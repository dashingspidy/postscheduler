module Publishing
  class Dispatcher
    def self.publish(post)
      Registry.fetch(post.publishing_provider).publish(post)
    end
  end
end
