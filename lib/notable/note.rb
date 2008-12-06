module Notable
  class Note
    include DataMapper::Resource

    property :id, Serial
    property :body, String, :length => 255, :nullable => false
    property :created_at, DateTime
    property :updated_at, DateTime

    def to_s
      created_at_to_s + ": " + body
    end

    def sent_today?
      t = Time.new
      (t.day == created_at.day) && (t.month == created_at.month) && (t.year == created_at.year)
    end

    def created_at_to_s
      if sent_today?
        "Today"
      else
        created_at.strftime('%d %b')
      end
    end
  end
end
