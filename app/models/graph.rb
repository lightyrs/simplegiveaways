class Graph

  attr_accessor :resource

  def initialize(resource)
    return unless @resource = resource
  end

  def page_likes
    return [] unless @resource.is_a? Giveaway
    @resource.facebook_page.audits.where("created_at >= ? AND created_at <= ?", @resource.start_date,
    @resource.end_date).where("id%3=0").map do |audit|
      if audit.is.has_key?(:likes)
        format_audit(audit, audit.is[:likes])
      end
    end.compact
  end

  def net_likes
    return [] unless @resource.is_a? Giveaway
    @resource.audits.where("id%3=0").map do |audit|
      if audit.is.has_key?(:analytics)
        format_audit(audit, audit.is[:analytics], :_page_likes_while_active)
      end
    end.compact
  end

  def entries
    return [] unless @resource.is_a? Giveaway
    @resource.audits.where("id%3=0").map do |audit|
      if audit.is.has_key?(:analytics)
        format_audit(audit, audit.is[:analytics], :_entry_count)
      end
    end.compact
  end

  def views
    return [] unless @resource.is_a? Giveaway
    @resource.audits.where("id%3=0").map do |audit|
      if audit.is.has_key?(:analytics)
        format_audit(audit, audit.is[:analytics], :_views)
      end
    end.compact
  end

  private

  def format_audit(audit, attr, key=nil)
    val = key ? attr[key] : attr
    val = 0 if val.nil?

    [js_timestamp(audit.created_at), val]
  end

  def js_timestamp(time)
    time.to_i * 1000
  end
end
