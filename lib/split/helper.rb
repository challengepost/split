module Split
  module Helper
    attr_accessor :ab_user

    def ab_test(experiment_name, control, *alternatives)
      puts 'WARNING: You should always pass the control alternative through as the second argument with any other alternatives as the third because the order of the hash is not preserved in ruby 1.8' if RUBY_VERSION.match(/1\.8/) && alternatives.length.zero?
      begin
        experiment = Split::Experiment.find_or_create(experiment_name, *([control] + alternatives))
        if experiment.winner
          ret = experiment.winner.name
        else
          if forced_alternative = override(experiment.name, experiment.alternative_names)
            ret = forced_alternative
          else
            clean_old_versions(experiment)
            begin_experiment(experiment) if exclude_visitor? or not_allowed_to_test?(experiment.key)

            if ab_user.get_key(experiment.key) 
              ret = ab_user.get_key(experiment.key)
            else
              alternative = experiment.next_alternative
              alternative.increment_participation
              begin_experiment(experiment, alternative.name)
              ret = alternative.name
            end
          end
        end
      rescue Errno::ECONNREFUSED => e
        raise unless Split.configuration.db_failover
        Split.configuration.db_failover_on_db_error.call(e)
        ret = Hash === control ? control.keys.first : control
      end
      if block_given?
        if defined?(capture) # a block in a rails view
          block = Proc.new { yield(ret) }
          concat(capture(ret, &block))
          false
        else
          yield(ret)
        end
      else
        ret
      end
    end

    def finished(experiment_name, options = {:reset => true})
      return if exclude_visitor?
      return unless (experiment = Split::Experiment.find(experiment_name))
      if alternative_name = ab_user.get_key(experiment.key)
        alternative = Split::Alternative.new(alternative_name, experiment_name)
        alternative.increment_completion
        ab_user.delete_key(experiment_name) if options[:reset]
      end
    rescue Errno::ECONNREFUSED => e
      raise unless Split.configuration.db_failover
      Split.configuration.db_failover_on_db_error.call(e)
    end

    def override(experiment_name, alternatives)
      begin
        params[experiment_name] if alternatives.include?(params[experiment_name])
      rescue
        nil
      end
    end

    def begin_experiment(experiment, alternative_name = nil)
      alternative_name ||= experiment.control.name
      ab_user.set_key(experiment.key, alternative_name)
    end

    def ab_user
      @ab_user ||= case Split.configuration.user_store
      when :session_store
        Split::SessionStore.new(session)
      when :redis_store
        Split::RedisStore.new(Split.redis)
      else
        raise "user_store type '#{Split.configuration.user_store}' unrecognized"
      end
    end

    def exclude_visitor?
      is_robot? or is_ignored_ip_address?
    end

    def not_allowed_to_test?(experiment_key)
      !Split.configuration.allow_multiple_experiments && doing_other_tests?(experiment_key)
    end

    def doing_other_tests?(experiment_key)
      ab_user.get_keys.reject{|k| k == experiment_key}.length > 0
    end

    def clean_old_versions(experiment)
      old_versions(experiment).each do |old_key|
        ab_user.delete_key old_key
      end
    end

    def old_versions(experiment)
      if experiment.version > 0
        ab_user.get_keys.select{|k| k.match(Regexp.new(experiment.name))}.reject{|k| k == experiment.key}
      else
        []
      end
    end

    def is_robot?
      if user_agent = request.try(:user_agent)
        user_agent =~ Split.configuration.robot_regex
      else
        false
      end
    end

    def is_ignored_ip_address?
      if Split.configuration.ignore_ip_addresses.any? && request.try(:ip)
        Split.configuration.ignore_ip_addresses.include?(request.ip)
      else
        false
      end
    end
  end
end
