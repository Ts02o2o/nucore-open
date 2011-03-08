class OrderStatus < ActiveRecord::Base
  acts_as_nested_set

  has_many :order_details

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:parent_id, :facility_id]
  validates_each :parent_id do |model, attr, value|
    begin
      model.errors.add(attr, 'must be a root') unless (value.nil? || OrderStatus.find(value).root?)
    rescue
      model.errors.add(attr, 'must be a valid root')
    end
  end

  named_scope :new_os,     :conditions => {:name => 'New'}, :limit => 1
  named_scope :inprocess,  :conditions => {:name => 'In Process'}, :limit => 1
  named_scope :cancelled,  :conditions => {:name => 'Cancelled'}, :limit => 1
  named_scope :reviewable, :conditions => {:name => 'Reviewable'}, :limit => 1

  def is_left_of? (o)
    rgt < o.lft
  end

  def is_right_of? (o)
    lft > o.rgt
  end

  def name_with_level
    "#{'-' * level} #{name}".strip
  end

  def to_s
    name
  end

  class << self
    def default_order_status
      roots.sort {|a,b| a.lft <=> b.lft }.first
    end

    def initial_statuses (facility)
      first_invalid_status = self.find_by_name('Cancelled')
      statuses = self.find(:all).sort {|a,b| a.lft <=> b.lft }.reject {|os|
        !os.is_left_of?(first_invalid_status)
      }
      statuses.reject! { |os| os.facility_id != facility.id && !os.facility_id.nil? } if !facility.nil?
      statuses
    end

    def non_protected_statuses (facility)
      first_protected_status = self.find_by_name('Complete')
      statuses = self.find(:all).sort {|a,b| a.lft <=> b.lft }.reject {|os|
        !os.is_left_of?(first_protected_status)
      }
      statuses.reject! { |os| os.facility_id != facility.id && !os.facility_id.nil? } if !facility.nil?
      statuses
    end

    def complete
      find_by_name!('Complete')
    end
  end
end
