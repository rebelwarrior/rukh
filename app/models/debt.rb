# -*- encoding : utf-8 -*-

# rubocop:disable Metrics/LineLength
class Debt < ActiveRecord::Base # TODO: create migration to prevent nulls on originating debt
  ## Hooks
  belongs_to :debtor, touch: true
  has_many :mail_logs, dependent: :restrict_with_exception
  # Dependend Destroy means:
  # if Debtor is erase so are all the debts associeated with.

  ## REGEX
  VALID_NUM_REGEX = /\A[[:digit:]]+\.?[[:digit:]]*\z/
  VALID_PERMIT_REGEX = \
    /\A[[:alpha:]]{2}-?[[:alpha:]]{2}-?[0-9]{2}-?[0-9]{2}-?[0-9]{2}-?[0-9]{1}\z/i
  VALID_INFRACTION_REGEX = /\A[[:alpha:]]-?[0-9]{2}-?[0-9]{2}-?[0-9]{3}-?[[:alpha:]]{2}\z/i
  VALID_PERMIT_OR_INFRACTION_REGEX = \
    /\A([[:alpha:]]{2}-?[[:alpha:]]{2}-?[0-9]{2}-?[0-9]{2}-?[0-9]{2}-?[0-9]{1})|([[:alpha:]]-?[0-9]{2}-?[0-9]{2}-?[0-9]{3}-?[[:alpha:]]{2})\z/i
  VALID_DATE_REGEX = \
    %r~\A([0-9]{1,2}(\/?|-?)[0-9]{1,2}(\/?|-?)[0-9]{4}|[0-9]{4}(\/?|-?)[0-9]{1,2}(\/?|-?)[0-9]{1,2})\z~
  VALID_ROUTING_NUM_REGEX = /(\A\z|\A[0-9]{9}\z)/

  ## Validations
  validates :debtor_id,          presence: true
  validates :original_debt_date, presence: true, format: { with: VALID_DATE_REGEX,
                                                           message: 'Debe ser una fecha.' }
  validates :amount_owed_pending_balance,        format: { with: VALID_NUM_REGEX,
                                                           message: 'Debe ser un número.' }
  validates :bounced_check_number,               format: { with: /\A[[:digit:]]*\z/i,
                                                           message: 'Debe ser un número.' }
  validates :permit_infraction_number,           format: { with: VALID_PERMIT_OR_INFRACTION_REGEX,
                                                           message: 'Debe ser un número de multa o permiso (o estar en blanco).' },
                                                 unless: proc { |debt_ex| debt_ex.permit_infraction_number.blank? }
  validates :bank_routing_number,                format: { with: VALID_ROUTING_NUM_REGEX,
                                                           message: 'Deber ser un número de nueve (9) digitos o estar en blanco.' }

  ## Methods
  def find_debtor_attr(debtor_id, attributes)
    result = []
    attributes.each do |attribute|
      attribute_clean = { name: :name, contact: :contact_person }.fetch(attribute)
      debtor = Debtor.find_by_id(debtor_id)
      result << (debtor.nil? ? 'NULL' : debtor.public_send(attribute_clean))
    end
    result
  end

  ## Export to CSV
  ## Calls to_plan_csv w/ correct options
  def self.to_csv(_options = {})
    to_plain_csv(%i[debtor_name contact_person]) do |extra_items, record|
      extra_items.push(record.find_debtor_attr(record.attributes['debtor_id'], %i[name contact]))
    end
  end

  ## Export to Plain CSV.
  def self.to_plain_csv(extra_column_names = [], options = {}, &block)
    require 'csv'
    CSV.generate(options) do |csv|
      csv.add_row(column_names + extra_column_names)
      all.each do |record|
        extra_items = []
        yield(extra_items, record) if block
        csv.add_row record.attributes.values_at(*column_names).concat(extra_items).flatten
      end
    end
  end
end
