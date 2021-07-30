require "./error"

# Analyze validation blocks and procs
#
# By example:
# ```
# validate :name, "can't be blank" do |user|
#   !user.name.to_s.blank?
# end
#
# validate :name, "can't be blank", ->(user : User) do
#   !user.name.to_s.blank?
# end
#
# name_required = ->(model : Granite::Base) { !model.name.to_s.blank? }
# validate :name, "can't be blank", name_required
# ```
module Granite::Validators
  @[JSON::Field(ignore: true)]
  @[YAML::Field(ignore: true)]
  getter errors = [] of Error

  macro included
    macro inherited
      @@validators = Array({field: String, message: String, block: Proc({{ @type.id }}, Bool)}).new

      disable_granite_docs? def self.validate(message : String, &block : {{ @type.id }} -> Bool)
        self.validate(:base, message, block)
      end

      disable_granite_docs? def self.validate(field : (Symbol | String), message : String, &block : {{ @type.id }} -> Bool)
        self.validate(field, message, block)
      end

      disable_granite_docs? def self.validate(message : String, block : {{ @type.id }} -> Bool)
        self.validate(:base, message, block)
      end

      disable_granite_docs? def self.validate(field : (Symbol | String), message : String, block : {{ @type.id }} -> Bool)
        @@validators << {field: field.to_s, message: message, block: block}
      end
      {%debug%}
    end
  end

  def valid?
    # Return false if any `ConversionError` were added
    # when setting model properties
    return false if errors.any? ConversionError

    errors.clear

    @@validators.each do |validator|
      unless validator[:block].call(self)
        errors << Error.new(validator[:field], validator[:message])
      end
    end

    errors.empty?
  end
end
