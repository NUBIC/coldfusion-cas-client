module ControllerModuleCommonSetup
  def setup
    configure_bcsec
    @controller = make_controller
  end
  
  def teardown
    Bcsec.configure do
      clear
    end
  end

  def configure_bcsec
    Bcsec.configure do
      clear
      permit_all = Class.new do
        def may_access?(*args)
          true
        end

        def valid_credentials?(*args)
          true
        end
      end.new

      authenticators permit_all
    end
  end

  def make_controller
    Class.new(ActionController::Base) do
      attr_reader :session

      def initialize
        @session = ActionController::TestSession.new
      end
    end.new
  end
end
