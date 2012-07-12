# -*- encoding : utf-8 -*-
class User < ActiveRecord::Base

  audited

  has_many :identities, :dependent => :destroy
  has_and_belongs_to_many :facebook_pages

  def avatar
    identities.find(:all, :order => "logged_in_at desc", :limit => 1).first.avatar
  end

  def retrieve_pages(jug_key)
    graph = Koala::Facebook::API.new(identities.where("provider = ?", "facebook").first.token)
    pages = graph.get_connections("me", "accounts")
    FacebookPage.retrieve_fb_meta(self, pages, jug_key)
  end
  handle_asynchronously :retrieve_pages

  ROLES = %w[superadmin admin team restricted banned]

  def is?(role)
    roles.include?(role.to_s)
  end

  def roles=(roles)
    self.roles_mask = (roles & ROLES).map { |r| 2**ROLES.index(r) }.sum
  end

  def roles
    ROLES.reject do |r|
      ((roles_mask || 0) & 2**ROLES.index(r)).zero?
    end
  end
end
