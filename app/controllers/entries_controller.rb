# -*- encoding : utf-8 -*-
class EntriesController < ApplicationController

  layout 'facebook_pages'

  before_filter :before_entry_callbacks, only: [:create]
  after_filter  :after_entry_callbacks, only: [:create]

  def create
    @entry = @giveaway.entries.new

    if params[:access_token]
      @entry = @entry.process(
        has_liked: params[:has_liked],
        referrer_id: params[:ref_id],
        access_token: params[:access_token],
        email: params[:email],
        giveaway_id: @giveaway.id,
        cookie: @giveaway_cookie
      )

      if @entry.persisted?
        @giveaway_cookie.entry_id = @entry.id
        if @giveaway.allow_multi_entries.truthy?
          @entry.update_attributes(entry_count: @entry.entry_count += 1)
          render json: @entry.as_json(only: %w(id shortlink)), status: :created
          ga_event("Entries", "Entry#multi", @entry.giveaway.title, @entry.id)
        else
          render json: @entry.as_json(only: %w(id shortlink wall_post_count request_count)), status: :not_acceptable
        end
      elsif @entry.status == "incomplete"
        render json: @entry.id, status: :precondition_failed
      elsif @entry.save
        @giveaway_cookie.entry_id = @entry.id
        render json: @entry.as_json(only: %w(id shortlink)), status: :created
        ga_event("Entries", "Entry#create", @entry.giveaway.title, @entry.id)
      else
        head :not_acceptable
      end
    else
      head :failed_dependency
    end
  end

  def update
    @entry = Entry.find(params[:id])
    if @entry.update_attributes(params[:entry])
      render text: @entry.id, status: :accepted
      ga_event("Entries", "Entry#update", @entry.id, nil)
    else
      head :not_acceptable
    end
  end

  def index
    @giveaway = Giveaway.find(params[:giveaway_id])
    @page = @giveaway.facebook_page
    @entries = @giveaway.entries
  end

  private

  def before_entry_callbacks
    assign_giveaway
    assign_giveaway_cookie
  end

  def after_entry_callbacks
    register_like_from_entry
    set_giveaway_cookie
  end

  def assign_giveaway
    @giveaway = Giveaway.find(params[:giveaway_id])
  end

  def assign_giveaway_cookie
    @giveaway_cookie = GiveawayCookie.new( cookies.encrypted[Giveaway.cookie_key(@giveaway.id)] )
  end

  def register_like_from_entry
    if @entry.uid && (@like = Like.find_by_fb_uid_and_giveaway_id(@entry.uid, @entry.giveaway_id))
      @like.update_attributes(
        entry_id: @giveaway_cookie.entry_id,
        from_entry: true
      )
    elsif @like = Like.find_by_id(params[:like_id])
      @like.update_attributes(
        entry_id: @giveaway_cookie.entry_id,
        from_entry: true,
        fb_uid: @entry.uid
      )
      if @like.invalid? && @like.errors.keys.include?(:entry_id)
        @like.destroy
      end
    end
  end

  def set_giveaway_cookie
    cookies.encrypted[Giveaway.cookie_key(@giveaway.id)] = @giveaway_cookie.to_json
  end
end
