module Diesel::Examples; end

class Diesel::Examples::FunWithParams
  include Diesel

  endpoint '/foo' do
    required :foo do
      type Array
      disallowed_values %w{zilch zip nada}
    end
  end

  endpoint '/bar' do
    required :foo do
      type Array, separator: '+'
    end
  end

  endpoint '/baz' do
    required :foo do
      type Array, separator: ','
    end
  end

  endpoint '/bar' do
    required :foo
  end

  endpoint '/foo/:bar' do
    required :bar do
      type Time
    end
  end

  endpoint '/protected' do
    protect do
      http_basic username: 'no', password: 'way'
    end
  end

  endpoint '/foo/:bar'
end