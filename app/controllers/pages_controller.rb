class PagesController < ApplicationController
  def home
    doc = Nokogiri::HTML(open(@chromeUrl))
    raise "hell"
  end
end
