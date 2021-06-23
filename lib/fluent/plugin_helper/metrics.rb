#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'forwardable'

require 'fluent/plugin'
require 'fluent/plugin/metrics'
require 'fluent/plugin_helper/timer'
require 'fluent/config/element'
require 'fluent/configurable'
require 'fluent/system_config'

module Fluent
  module PluginHelper
    module Metrics
      include Fluent::SystemConfig::Mixin

      def initialize
        super
        @_metrics = {} # usage => metrics_state
      end

      def configure(conf)
        super
      end

      def metrics_create(namespace: "Fluentd", subsystem: "metrics", name:, help_text:, labels: {}, prefer_gauge: false)
        metrics = if system_config.metrics
                    Fluent::Plugin.new_metrics(system_config.metrics[:@type], parent: self)
                  else
                    Fluent::Plugin.new_metrics(Fluent::Plugin::Metrics::DEFAULT_TYPE, parent: self)
                  end
        config = if system_config.metrics
                   system_config.metrics.corresponding_config_element
                 else
                   Fluent::Config::Element.new('metrics', '', {'@type' => Fluent::Plugin::Metrics::DEFAULT_TYPE}, [])
                 end
        metrics.use_gauge_metric = prefer_gauge
        metrics.configure(config)
        metrics.create(namespace: namespace, subsystem: subsystem, name: name, help_text: help_text, labels: labels.merge(worker_id: fluentd_worker_id.to_s))

        @_metrics["#{self.plugin_id}_#{namespace}_#{subsystem}_#{name}"] = metrics

        metrics
      end

      def terminate
        @_metrics = {}
        super
      end
    end
  end
end