#
# Copyright 2012-2013 eNovance <licensing@enovance.com>
#
# Author: Julien Danjou <julien@danjou.info>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import msgpack
from oslo.config import cfg
import oslo.messaging

from ceilometer import dispatcher
from ceilometer import messaging
from ceilometer.openstack.common.gettextutils import _
from ceilometer.openstack.common.gettextutils import _LE
from ceilometer.openstack.common import log
from ceilometer.openstack.common import service as os_service

OPTS = [
    cfg.StrOpt('topic',
               default='notifications',
               help='The message queue topic to which the router listens on.'),
    cfg.StrOpt('priority',
               default='info',
               help='The message queue priority.'),
    cfg.BoolOpt('requeue_on_error',
                default=False,
                help='Re-queue the messages on the router message queue '
                'when the router fails to route it.'),
]

cfg.CONF.register_opts(OPTS, group="consumer")

LOG = log.getLogger(__name__)


class ConsumerService(os_service.Service):
    """Listener for the collector service."""
    def start(self):
        self.dispatcher_manager = dispatcher.load_dispatcher_manager()
        self.notification_server = None
        super(ConsumerService, self).start()

        allow_requeue = cfg.CONF.consumer.requeue_on_error
        transport = messaging.get_transport(optional=True)
        if transport:
            self.rpc_server = messaging.get_rpc_server(
                transport, cfg.CONF.consumer.topic, self)

            target = oslo.messaging.Target(
                topic=cfg.CONF.consumer.topic)
            self.notification_server = messaging.get_notification_listener(
                transport, [target],
                [ConsumerEndpoint(self.dispatcher_manager,
                                  'record_metering_data',
                                  cfg.CONF.consumer.priority)],
                allow_requeue=allow_requeue)

            self.notification_server.start()

    def stop(self):
        if self.notification_server:
            self.notification_server.stop()
        super(ConsumerService, self).stop()

    def record_metering_data(self, context, data):
        """RPC endpoint for messages we send to ourselves.

        When the notification messages are re-published through the
        RPC publisher, this method receives them for processing.
        """
        LOG.debug('calling record_metering_data from the service')
        self.dispatcher_manager.map_method('record_metering_data', data=data)

class ConsumerEndpoint(object):
    def __init__(self, dispatcher_manager, method, priority):
        self.dispatcher_manager = dispatcher_manager
        self.requeue_on_error = cfg.CONF.consumer.requeue_on_error
        self.method = method
        self.priority = priority
        setattr(self, self.priority, self._handler)

    def _handler(self, ctxt, publisher_id, event_type, payload, metadata):
        """RPC endpoint for notification messages

        When another service sends a notification over the message
        bus, this method receives it.
        """
        try:
            LOG.debug('calling endpoint _handler')
            self.dispatcher_manager.map_method(self.method, payload)
        except Exception:
            if self.requeue_on_error:
                LOG.exception(_LE("Dispatcher failed to handle the %s, "
                                  "requeue it."), self.priority)
                return oslo.messaging.NotificationResult.REQUEUE
            raise
