class SyncedFilesController < ApplicationController
  before_filter :set_page_title
  
  def index
    params[:path] ||= ""
    @path = "/#{params[:path]}"
    @folders = params[:path].split("/")
    @parent = (@folders[0,@folders.length-1] || []).join("/")
    
    @nomadesk = Nomadesk.new(:user => "nomadesk@teambox.com", :pass => "papapa")
    @bucket = @nomadesk.find_bucket('nmsa120663')
    @files = @nomadesk.list(@bucket, params[:path])
    
    @upload_url = @nomadesk.file_upload_url(@bucket, @path)
  end
  
  def new
    @path = "/#{params[:path]}"
    @nomadesk = Nomadesk.new(:user => "nomadesk@teambox.com", :pass => "papapa")
    @bucket = @nomadesk.find_bucket('nmsa120663')
    
    @upload_url = @nomadesk.file_upload_url(@bucket, @path)
  end
end
