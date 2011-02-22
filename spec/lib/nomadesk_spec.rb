require 'spec_helper'

describe Nomadesk do
  it "should raise an error if created without a username and password" do
    lambda { Nomadesk.new() }.should raise_error(ArgumentError)
  end
  
  it "shouldn't raise an error if created with a username and password" do
    lambda { Nomadesk.new(:user => 'test', :pass => 'test') }.should_not raise_error
  end
  
  describe "with valid authentication params" do
    before(:each) do
      @nomadesk = Nomadesk.new(:user => "nomadesk@teambox.com", :pass => "papapa")
    end
    
    it "should present an access token when sent #token" do
      @nomadesk.token.should be_an_instance_of Nomadesk::Token
      @nomadesk.token.key.should_not be_blank
      @nomadesk.token.key.length.should == 26
    end
    
    it "should present a list of buckets when sent #buckets" do
      buckets = @nomadesk.buckets
      
      buckets.should be_instance_of(Array)
      
      buckets.first.should be_instance_of(Nomadesk::Bucket)
      buckets.first.name.should == "nmsa120663"
      buckets.first.label.should == "Teambox-fs2"
    end
  
    it "should present a list of files when sent #list with a bucket" do
      bucket = @nomadesk.buckets.first
      
      items = @nomadesk.list(bucket)
      
      items.should be_instance_of(Array)
      items.first.should be_instance_of(Nomadesk::Item)
      items.first.name.should == "this is a folder"
      items.first.path.should == "/"
      items.first.is_folder?.should be_true
      items.first.modified.should == DateTime.new(2011, 02, 04, 12, 11, 04)
      
      items.second.is_folder?.should be_false
    end
    
    it "should find a bucket given it's name when sent #find_bucket with the name" do
      bucket = @nomadesk.find_bucket('nmsa120663')
      bucket.name.should == "nmsa120663"
      bucket.label.should == "Teambox-fs2"
    end
    
    it "should present a download link when sent #download link with a bucket and a path" do
      bucket = @nomadesk.buckets.first
      item = @nomadesk.list(bucket).second # This is a file not dir
      
      expected = "https://secure005.nomadesk.com/nomadesk-storage/api.php?FileserverName=#{bucket.name}&Token=#{@nomadesk.token.key}&Task=FileDownload&Path=#{item.path}#{ERB::Util.url_encode(item.name)}"
      @nomadesk.download_url(bucket, item.full_path).should == expected
    end
    
    it "should allow direct access to a download link from the item" do
      bucket = @nomadesk.buckets.first
      item = @nomadesk.list(bucket).second # This is a file not dir
      item.download_url.should_not be_blank
    end
    
    # TODO: Add tests for all the methods that generate urls etc. At the moment these are basically just functional tests
  end
end
