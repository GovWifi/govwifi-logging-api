# frozen_string_literal: true

class MacFormatter
  def execute(mac:)
    ietf_format(only_hex(uppercase(mac.to_s)))
  end

private

  def uppercase(mac)
    mac.upcase
  end

  def only_hex(mac)
    mac.gsub(/[^0-F]/, "")
  end

  def ietf_format(mac)
    "#{mac[0, 2]}-#{mac[2, 2]}-#{mac[4, 2]}-#{mac[6, 2]}-#{mac[8, 2]}-#{mac[10, 2]}"
  end
end
