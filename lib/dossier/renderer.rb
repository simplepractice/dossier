module Dossier
  class Renderer
    attr_reader :report
    attr_writer :engine
    
    # Conditional for Rails 4.1 or < 4.1 Layout module
    Layouts = defined?(ActionView::Layouts) ? ActionView::Layouts : AbstractController::Layouts

    def initialize(report)
      @report = report
    end

    def render(options = {})
      render_template :custom, options
    rescue ActionView::MissingTemplate => e
      render_template :default, options
    end

    def engine
      @engine ||= Engine.new(report)
    end

    private

    def render_template(template, options)
      template = send("#{template}_template_path")
      engine.render options.merge(template: template, locals: {report: report})
    end

    def template_path(template)
      "dossier/reports/#{template}"
    end

    def custom_template_path
      template_path(report.template)
    end

    def default_template_path
      template_path('show')
    end

    class Engine < AbstractController::Base
      include AbstractController::Rendering
      include Renderer::Layouts
      include ViewContextWithReportFormatter
      
      attr_reader :report

      layout 'dossier/layouts/application'

      def self._helpers
        Module.new do
          include Rails.application.helpers
          include Rails.application.routes_url_helpers
        end
      end

      def self._view_paths
        ActionController::Base.view_paths
      end

      def initialize(report)
        @report = report
        super()
      end
    end
  end
end
