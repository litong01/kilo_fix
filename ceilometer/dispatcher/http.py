# Copyright 2013 IBM Corp
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

import json

from oslo.config import cfg
from ceilometer.openstack.common import log
import requests

from ceilometer import dispatcher
from ceilometer.openstack.common.gettextutils import _
from ceilometer.openstack.common.gettextutils import _LE

LOG = log.getLogger(__name__)

CADF_TYPEURI = u"http://schemas.dmtf.org/cloud/audit/1.0/event"

http_dispatcher_opts = [
    cfg.StrOpt('target',
               default='',
               help='The target where the http request will be sent. '
                    'If this is not set, no data will be posted. For '
                    'example: target = http://hostname:1234/path'),
    cfg.BoolOpt('cadf_only',
                default=False,
                help='The flag that indicates if only cadf message should '
                     'be posted. If false, all meters will be posted.'),
    cfg.IntOpt('timeout',
               default=5,
               help='The max time in seconds to wait for a request to '
                    'timeout.'),
]

cfg.CONF.register_opts(http_dispatcher_opts, group="dispatcher_http")


class HttpDispatcher(dispatcher.Base):
    """Dispatcher class for posting metering data into a http target.

    To enable this dispatcher, the following option needs to be present in
    ceilometer.conf file::

        [DEFAULT]
        dispatcher = http

    Dispatcher specific options can be added as follows::

        [dispatcher_http]
        target = www.example.com
        cadf_only = true
        timeout = 2
    """
    def __init__(self, conf):
        super(HttpDispatcher, self).__init__(conf)
        self.headers = {'Content-type': 'application/json'}
        self.timeout = self.conf.dispatcher_http.timeout
        self.target = self.conf.dispatcher_http.target
        self.cadf_only = self.conf.dispatcher_http.cadf_only

    def record_metering_data(self, data):
        if self.target == '':
            # if the target was not set, do not do anything
            LOG.error(_('Dispatcher target was not set, no meter will '
                        'be posted. Set the target in the ceilometer.conf '
                        'file'))
            return

        # We may have receive only one counter on the wire
        if not isinstance(data, list):
            data = [data]

        for msg in data:
            LOG.debug(msg)
            try:
                if self.cadf_only:
                    if msg.get('request', {}).get('CADF_EVENT'):
                        msg = msg.get('request').get('CADF_EVENT')
                    elif msg.get('typeURI') != CADF_TYPEURI:
                        LOG.debug(_('Message type %s does match CADF message '
                                  'type') % msg.get('typeURI'))
                        continue

                res = requests.post(self.target,
                                    data=json.dumps(msg),
                                    headers=self.headers,
                                    timeout=self.timeout)
                LOG.debug(_('Message posting finished with status code '
                            '%d.') % res.status_code)
            except Exception as err:
                LOG.exception(_('Failed to record metering data: %s'),
                              err)

    def record_events(self, events):
        """ Juno does not support event recording yet"""
        pass
