require 'virtus'
require 'currency'

class Snapshot
  include Virtus

  attribute :base, String, default: 'EUR'
  attribute :date, Date

  def quote
    self.date = if date
      Currency.where("date <= '#{date}'").order(:date).last.date
    else
      Currency.last_date
    end

    attributes.merge(rates: rebase(rates))
  end

  private

  def rates
    Currency.where(date: date).reduce({}) do |rates, currency|
      rates.update(currency.to_hash)
    end
  end

  def rebase(rates)
    if base.upcase! != 'EUR'
      denominator = rates.update('EUR' => 1.0).delete(base)

      rates.each do |iso_code, rate|
        rates[iso_code] = round(rate / denominator)
      end
    end

    rates
  end

  def round(rate)
    if rate > 100
      rate.round(2)
    elsif rate > 10
      rate.round(3)
    else
      rate.round(4)
    end
  end
end
