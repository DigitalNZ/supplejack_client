# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

module Supplejack
  class RecordNotFound < StandardError
  end

  class SetNotFound < StandardError
  end

  class MalformedRequest < StandardError
  end
end
