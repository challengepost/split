require 'spec_helper'
require 'split/redis_store'

describe Split::RedisStore do
  include Split::Helper

  before(:each) do
    Split.redis.flushall

    @store = Split::RedisStore.new(Split.redis)
  end

  it "gets/sets a key" do
    @store.set_key(:foo, :bar)
    @store.get_key(:foo).should eql('bar')
  end

  it "gets all keys" do
    @store.set_key(:foo, :bar)
    @store.set_key(:baz, :bar)

    @store.get_keys.should include('foo')
    @store.get_keys.should include('baz')
    @store.get_keys.length.should eql(2)
  end

  it "deletes a key" do
    @store.set_key(:foo, :bar)
    @store.set_key(:baz, :bar)
    @store.delete_key(:foo)

    @store.get_keys.should eql(['baz'])
  end

  it "returns as a hash" do
    @store.set_key(:foo, :bar)
    @store.set_key(:baz, :bar)

    @store.to_hash.should eql({'foo' => 'bar', 'baz' => 'bar'})
  end

  it "loads and performs as a Split user store" do
    Split.configure do |config|
      config.user_store = :redis_store
    end

    ab_user.should respond_to(:redis)
    ab_user.set_key(:foo, :bar)
    ab_user.set_key(:baz, :bar)
    ab_user.get_key(:foo).should eql('bar')
    ab_user.get_keys.should include('foo')
    ab_user.get_keys.should include('baz')
    ab_user.get_keys.length.should eql(2)
    ab_user.to_hash.should eql({'foo' => 'bar', 'baz' => 'bar'})
    ab_user.delete_key(:foo)
    ab_user.get_keys.should_not include('foo')
  end
end
