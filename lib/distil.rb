require 'active_support/core_ext'
require 'distil/version'
require 'distil/logger'
require 'distil/errors'
require 'distil/value_or_error'
require 'distil/response_context'
require 'distil/rack_interface'
require 'distil/doc/router_doc'
require 'distil/doc/endpoint_doc'

require 'distil/dsl_subject'

require 'distil/dsl_subjects/router'
require 'distil/dsl_subjects/parameter'
require 'distil/dsl_subjects/protection'
require 'distil/dsl_subjects/parameter_block'
require 'distil/dsl_subjects/endpoint'

module Distil
  class NYI < StandardError; end

  def self.included(base)
    unless base.respond_to?(:root)
      raise ArgumentError.new(
        "Please define #{base}.root to return the path to your app"
      )
    end

    base.extend(RackInterface)

    class << base
      alias_method :orig_mm, :method_missing
      alias_method :orig_respond_to?, :respond_to?

      def __router
        @__router ||= Distil::DSLSubjects::Router.new(self)
      end

      def __logger
        @__logger ||= begin
          if self.orig_respond_to?(:logger) && self.logger.is_a?(ActiveSupport::BufferedLogger)
            self.logger
          else
            Distil::Logger.new(self.root)
          end
        end
      end

      def respond_to?(m)
        orig_respond_to?(m) || (__router && __router.dsl_proxy.respond_to?(m))
      end

      def method_missing(m, *args, &block)
        if __router.dsl_proxy.respond_to?(m)
          __router.dsl_proxy.send(m, *args, &block)
        elsif m == :logger
          __logger
        else
          orig_mm(m, *args, &block)
        end
      end

      def to_docs
        app_name = self.name.split('::').last
        
        `mkdir -p ./distil_docs/#{app_name}/`

        home = File.new("./distil_docs/#{app_name}/Home.md", "w")
        home.write(__router.to_md(app_name))
        home.close

        __router.endpoints.each do |endpoint|
          endpoint_page = File.new("./distil_docs/#{app_name}/#{endpoint.doc_file_name}.md", "w")
          endpoint_page.write(endpoint.to_md)
          endpoint_page.close
        end
      end
    end
  end

  def self.env
    ENV['RACK_ENV']
  end

  [:development?, :production?, :staging?, :test?].each do |m|
    define_singleton_method(m) do
      env == m.to_s[0..-2]
    end
  end

  def self.development?
    true
  end
end

Diesel = Distil
