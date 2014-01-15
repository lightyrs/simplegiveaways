require 'dotiw'

module GiveawaysHelper

  include PublicUtils

  include ActionView::Helpers::DateHelper

  def time_from_now(time, options = {})
    only_options = if options[:only]
      options[:only]
    elsif time.between?(1.seconds.ago, 24.hours.from_now)
      %w(hours minutes)
    elsif time > 1.month.from_now
      %w(months days)
    elsif time > 1.year.from_now
      %w(years months)
    elsif time.between?(2.seconds.ago, 24.hours.ago)
      %w(hours)
    elsif time.between?(24.hours.ago, 1.month.ago)
      %w(days)
    elsif time.between?(1.month.ago, 1.year.ago)
      %w(months days)
    elsif time < 1.year.ago
      %w(years months)
    else
      %w(days hours)
    end

    accumulate_options = only_options.first.to_sym rescue :days

    distance_of_time_in_words(Time.now, time, false, only: only_options, accumulate_on: accumulate_options)
  end

  def giveaway_header_class(giveaway)
    case giveaway.status
      when 'Active'
        'bg-primary'
      when 'Pending'
        'bg-dark'
      when 'Completed'
        'bg-danger'
    end
  end

  def status_label(giveaway)
    case giveaway.status
      when 'Active'
        active_status_label(giveaway)
      when 'Pending'
        pending_status_label(giveaway)
      when 'Completed'
        completed_status_label(giveaway)
    end
  end

  def active_status_label(giveaway)
    label = <<-eos
      <div class="ui ribbon label teal">
        <strong>Active</strong><br />
        Started on #{datetime_mdy(giveaway.start_date)}<br />
        Ends on #{datetime_mdy(giveaway.end_date)}
      </div>
    eos
    label.html_safe
  end

  def pending_status_label(giveaway)
    label = <<-eos
      <div class="ui ribbon label">
        <strong>Pending</strong><br />
    eos
    if giveaway.start_date
      label += <<-eos
        Starts on #{datetime_mdy(giveaway.start_date)}
      eos
    end
    if giveaway.end_date
      label += <<-eos
        <br />
        Ends on #{datetime_mdy(giveaway.end_date)}
      eos
    end
    label += "</div>"
    label.html_safe
  end

  def completed_status_label(giveaway)
    label = <<-eos
      <div class="ui ribbon label red">
        <strong>Completed</strong><br />
        Started on #{datetime_mdy(giveaway.start_date)}<br />
        Ended on #{datetime_mdy(giveaway.end_date)}
      </div>
    eos
    label.html_safe
  end

  def boolean_label(boolean)
    if to_bool(boolean)
      '<span class=\'label bg-primary\'>TRUE</span>'.html_safe
    else
      '<span class=\'label bg-danger\'>FALSE</span>'.html_safe
    end
  end

  def start_date_label(giveaway, options = {})
    return "No Start Date" unless giveaway.start_date

    start_date = if options[:blank]
      nil
    elsif options[:relative]
      time_from_now(giveaway.start_date)
    else
      giveaway.start_date
    end

    return start_date if giveaway.active? || giveaway.completed?
    if giveaway.cannot_schedule?
      "<span class=\"giveaway-start-date-warning\" data-toggle=\"popover\" data-placement=\"auto top\" data-html=\"true\" data-title=\"<p>Inactive Start Date\" data-content=\"A Pro subscription is required in order to schedule a giveaway.</p><a class='btn btn-primary btn-block' href='#{facebook_page_subscription_plans_path(giveaway.facebook_page)}''>Choose a Plan</a>\"><s>#{start_date}</s></span>".html_safe
    elsif giveaway.has_scheduling_conflict?
      "<span class=\"giveaway-start-date-warning\" data-toggle=\"popover\" data-placement=\"auto top\" data-html=\"true\" data-title=\"Inactive Start Date\" data-content=\"<p>This giveaway has scheduling conflicts with the following giveaways:</p><p>#{conflicts(giveaway)}</p><p>Please update your giveaway schedules in order to activate this start date.</p><a class='btn btn-default btn-block' href='#{edit_facebook_page_giveaway_path(giveaway.facebook_page, giveaway)}'><i class='fa fa-pencil'></i>&nbsp;&nbsp;Edit Giveaway</a>\"><s>#{start_date}</s></span>".html_safe
    else
      start_date
    end
  end

  def end_date_label(giveaway, options = {})
    return "No End Date" unless giveaway.end_date

    end_date = if options[:blank]
      nil
    elsif options[:relative]
      "#{time_from_now(giveaway.start_date)} ago"
    else
      giveaway.end_date
    end

    return end_date if giveaway.completed?
    if giveaway.cannot_schedule?
      "<span class='giveaway-end-date-warning' data-toggle='popover' data-placement='auto top' data-html='true' data-title='Inactive End Date' data-content='<p>A Pro subscription is required in order to schedule a giveaway.</p><a class=\"btn btn-primary btn-block\" href=\"#{facebook_page_subscription_plans_path(giveaway.facebook_page)}\">Choose a Plan</a>'><s>#{end_date}</s></span>".html_safe
    elsif giveaway.has_scheduling_conflict?
      "<span class=\"giveaway-end-date-warning\" data-toggle=\"popover\" data-placement=\"auto top\" data-html=\"true\" data-title=\"Inactive End Date\" data-content=\"<p>This giveaway has scheduling conflicts with the following giveaways:</p><p>#{conflicts(giveaway)}</p><p>Please update your giveaway schedules in order to activate this end date.</p><a class='btn btn-default btn-block' href='#{edit_facebook_page_giveaway_path(giveaway.facebook_page, giveaway)}'><i class='fa fa-pencil'></i>&nbsp;&nbsp;Edit Giveaway</a>\"><s>#{end_date}</s></span>".html_safe
    else
      end_date
    end
  end

  def conflicts(giveaway)
    giveaway.all_conflicts.map do |g|
      "<a href='#{facebook_page_giveaway_path(g.facebook_page, g)}'>#{g.title}</a>"
    end.join('<br />')
  end
end
