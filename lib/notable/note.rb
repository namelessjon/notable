module Notable
  class Note
    include DataMapper::Resource

    property :id, Serial
    property :body, String, :length => 255, :nullable => false
    property :created_at, DateTime
    property :updated_at, DateTime
  end
end
