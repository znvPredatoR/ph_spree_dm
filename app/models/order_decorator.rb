module Spree
  Order.class_eval do

    attr_accessible :added_credits_amount

    Spree::Order.state_machine.before_transition :from => :payment,
                                                 :do => :valid_credits?
    Spree::Order.state_machine.before_transition :to => :complete,
                                                 :do => :valid_credits?

    def valid_credits?
      if Spree::Config[:ph_store_credit_minimum] and self.item_total < Spree::Config[:ph_store_credit_minimum].to_f and self.store_credit_amount > 0
        self.errors[:base] <<  "Order's item total is less than the minimum allowed (#{Spree::Config[:ph_store_credit_minimum].to_f.round(0)}) to use store credit."
        return false
      end
      return true
    end

    def finalize_with_add_users_credit!
      add_users_credit
      finalize_without_add_users_credit!
    end

    alias_method_chain :finalize!, :add_users_credit

    private

    def add_users_credit
      credit_rate = Spree::Config[:ph_store_credit_rate].to_f / 10
      bonus_per_each = Spree::Config[:ph_store_credit_bonus_per_each].to_i
      bonus_amount = Spree::Config[:ph_store_credit_bonus_amount].to_i

      self.added_credits_amount = (self.total * credit_rate).round

      #add bonus_amount per each bonus_per_each
      self.added_credits_amount += (self.total / bonus_per_each).floor * bonus_amount

      user.store_credits.create :amount => self.added_credits_amount,
                                :remaining_amount => self.added_credits_amount,
                                :reason => "For purchasing products."
    end

  end
end
