# Copyright 2018 SUSE LINUX GmbH, Nuernberg, Germany.
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

class TestUtils(object):

    @staticmethod
    def environment(cls):
        env_file = os.environ.get('ENVIRONMENT_JSON', '../caasp-kvm/environment.json')

        with open(env_file, 'r') as f:
            env = json.load(f)
            return env

    @staticmethod
    def feature_matches(cls, feature, value):
        feature_data = cls.environment().get("features", {}).get(feature, {})
        
        return set(feature_data.items()).issubset(set(value.items()))
