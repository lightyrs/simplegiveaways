# -*- encoding : utf-8 -*-
class FacebookPage < ActiveRecord::Base

  include ActionView::Helpers::UrlHelper

  attr_accessible :name, :category, :pid, :token, :avatar_square, :avatar_large,
                  :description, :likes, :url, :has_added_app

  has_many :audits, as: :auditable

  has_many :giveaways
  has_and_belongs_to_many :users

  validates :pid, uniqueness: true

  def self.retrieve_fb_meta(user, pages, csrf_token)
    pages = FacebookPage.select_pages(pages).compact.flatten
    page_count = (pages.size - 1)

    pages.each_with_index do |page_hash, index|
                  page = page_hash[:page]
               fb_meta = page_hash[:fb_meta][:data]
      fb_avatar_square = page_hash[:fb_meta][:avatar_square]
       fb_avatar_large = page_hash[:fb_meta][:avatar_large]

      @page = FacebookPage.find_or_create_by_pid(page["id"])

      previous_likes = @page.likes || fb_meta["likes"]

      @page.update_attributes(
        name: page["name"],
        category: page["category"],
        pid: page["id"],
        token: page["access_token"],
        avatar_square: fb_avatar_square,
        avatar_large: fb_avatar_large,
        description: fb_meta["description"],
        url: fb_meta["link"],
        likes: fb_meta["likes"],
        has_added_app: fb_meta["has_added_app"]
      )

      jug_data = { markup: @page.preview_template(previous_likes),
                   menu_item: @page.menu_item_template,
                   is_last: "#{index == page_count}" }

      Juggernaut.url = ENV["REDISTOGO_URL"]
      Juggernaut.publish("users#show_#{csrf_token}", jug_data.to_json)

      unless user.facebook_pages.include? @page
        @page.refresh_likes
        user.facebook_pages << @page
      end
    end
  end

  def refresh_likes
    batch = FacebookPage.graph_data(self)

    self.likes = batch[:data]["likes"]
    self.audits << likes_audit
    save
  end

  def likes_audit
    Audit.new(
      was: { likes: likes_was },
      is: { likes: likes }
    )
  end

  def page_admin_emails
    users.map do |user|
      user.identities.first.email if user
    end
  end

  def self.select_pages(pages)
    pages = pages.reject do |page|
      page["category"] == "Application"
    end

    pages.collect do |page|
      if FacebookPage.page_eligible?(batch = FacebookPage.graph_data(page))
        { page: page, fb_meta: batch }
      end
    end
  end

  def self.graph_data(page)
    batch = FacebookPage.batch_data(page)

    fb_meta          = batch[0]
    fb_avatar_square = batch[1]
    fb_avatar_large  = batch[2]

    { data: fb_meta,
      avatar_square: fb_avatar_square,
      avatar_large: fb_avatar_large }
  end

  def self.batch_data(page)
    @token = page["access_token"] || page.token
    @graph = Koala::Facebook::API.new(@token)

    @graph.batch do |batch_api|
      batch_api.get_object("me")
      batch_api.get_picture("me", type: "square")
      batch_api.get_picture("me", type: "large")
    end
  end

  def self.page_eligible?(batch)
    batch[:data]["link"].include? "facebook.com"
  end

  def has_free_trial?
    !used_free_trial?
  end

  def used_free_trial?
    entries = giveaways.map(&:entry_count).reject { |count| count == 0 } rescue []
    entries.any?
  end

  def menu_item_template
    <<-eos
      <li><a href=#{path} data-fb-pid=#{pid}>#{name}</a></li>
    eos
  end

  def preview_template(previous_likes)
    <<-eos
      <div class="facebook_page_preview" data-fb-pid="#{pid}">
        <div class="image">
          <a class="avatar" href="#{path}">
            <img alt="#{name}" src="#{avatar_square}" height="100" width="100">
          </a>
        </div>
        <div class="title">
          <h1><a href="#{path}">#{name}</a></h1>
          <h2>
            <span class="dynamo" data-lines="#{likes}">#{previous_likes}</span>
            <span class="gray">Likes</span>
          </h2>
        </div>
        <div class="buttons">
          <a class="btn btn-large btn-edit" href="#{path}">
            <i class="icon-flag"></i>
            Manage Page
          </a>
        </div>
      </div>
    eos
  end

  def path
    Rails.application.routes.url_helpers.facebook_page_path(self)
  end
end
