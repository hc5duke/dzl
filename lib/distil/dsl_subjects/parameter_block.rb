require 'distil/dsl_proxies/parameter_block'

class Distil::DSLSubjects::ParameterBlock < Distil::DSLSubject
  attr_accessor :params
  attr_reader :router

  def initialize(name, opts, router)
    @name   = name
    @opts   = opts
    @router = router
    @params = {}
    @dsl_proxy = Distil::DSLProxies::ParameterBlock.new(self)
  end

  def validate(parandidates, request)
    errors = @params.each_with_object({}) do |pary, errors|
      pname, param = pary
      parandidate_key = param.opts[:header] ? :headers : :params

      # verror = value or error.
      verror = @params[pname].validate(parandidates[parandidate_key][pname])
      if verror.error?
        errors[pname] = verror.error
      else
        parandidates[parandidate_key][pname] = verror.value unless verror.value == :__no_value__
      end
    end || {}

    # Check for extra request params we are not expecting
    parandidates[:params].each do |pname, value|
      unless @params.keys.include?(pname)
        parandidates[:params].delete(pname)
        errors[pname] = :unknown_param
      end
    end

    if !errors.empty?
      Distil::ValueOrError.new(e: errors)
    elsif @opts[:protection]
      protection_errors = @opts[:protection].collect do |protection|
        protection.allow?(parandidates, request)
      end.select { |result| result.error? }

      if protection_errors.empty?
        Distil::ValueOrError.new(v: parandidates)
      else
        protection_errors[0]
      end
    else
      Distil::ValueOrError.new(v: parandidates)
    end
  end

  def to_s
    "pblock:#{name}"
  end

  def as_json(opts=nil)
    {
      opts: @opts,
      params: @params
    }
  end
end