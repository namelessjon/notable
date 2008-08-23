
module Notable
  class NoteTaker < ::Uppercut::Agent

    command /^last ?(\d+)?$/ do |c, rest|
      last = rest.to_i unless rest.nil?
      notes = Note.all(:limit => (last||5), :order => [:created_at.desc])
      c.send(notes.map {|n| n.body }.join("\n"))
    end

    command /^(.*)$/ do |c, rest|
      Note.create(:body => rest.strip)
    end
  end
end
