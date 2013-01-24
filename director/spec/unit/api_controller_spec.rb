# Copyright (c) 2009-2012 VMware, Inc.

require File.expand_path("../../spec_helper", __FILE__)

require "rack/test"

describe Bosh::Director::ApiController do
  include Rack::Test::Methods

  before(:each) do
    @temp_dir = Dir.mktmpdir
    @blobstore_dir = File.join(@temp_dir, "blobstore")
    FileUtils.mkdir_p(@blobstore_dir)
    FileUtils.mkdir_p(@temp_dir)

    test_config = YAML.load(spec_asset("test-director-config.yml"))
    test_config["dir"] = @temp_dir
    test_config["blobstore"] = {
        "plugin" => "local",
        "properties" => {"blobstore_path" => @blobstore_dir}
    }
    BD::Config.configure(test_config)
    basic_authorize "admin", "admin"
  end

  after(:each) do
    FileUtils.rm_rf(@temp_dir)
  end

  def app
    @manager = mock(BD::Api::ResourceManager)
    BD::Api::ResourceManager.stub!(:new).and_return(@manager)
    Bosh::Director::ApiController.new
  end

  it "cleans up temp file after serving it" do
    tmp_file = File.join(Dir.tmpdir,
                         "resource-#{UUIDTools::UUID.random_create}")

    File.open(tmp_file, "w") do |f|
      f.write("some data")
    end

    FileUtils.touch(tmp_file)
    @manager.should_receive(:get_resource_path).with("deadbeef").and_return(tmp_file)

    File.exists?(tmp_file).should be_true
    get "/resources/deadbeef"
    last_response.body.should == "some data"
    File.exists?(tmp_file).should be_false
  end
end