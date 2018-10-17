# Copyright 2017 SUSE LINUX GmbH, Nuernberg, Germany.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import pytest


@pytest.mark.admin
class TestKubicAdmin(object):
    """docstring for TestBaseEnv"""

    @pytest.mark.bootstrapped
    @pytest.mark.parametrize("service", [
        "docker",
        "container-feeder",
        "kubelet",
    ])
    def test_services_running(self, host, service):
        host_service = host.service(service)
        assert host_service.is_running

    @pytest.mark.bootstrapped
    @pytest.mark.parametrize("service", [
        "docker",
        "container-feeder",
        "kubelet",
    ])
    def test_services_enabled(self, host, service):
        host_service = host.service(service)
        assert host_service.is_enabled

    @pytest.mark.bootstrapped
    def test_salt_role(self, host):
        assert 'admin' in host.salt("grains.get", "roles")

    @pytest.mark.bootstrapped
    def test_etcd_aliveness(self, host):
        cmd = "etcdctl cluster-health"
        health = host.run_expect([0], cmd)
        assert "cluster is healthy" in health.stdout
