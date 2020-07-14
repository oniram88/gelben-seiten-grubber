require "google/apis/sheets_v4"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"


OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Google Sheets API Ruby Quickstart".freeze
CREDENTIALS_PATH = "credentials.json".freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = "token.yaml".freeze
SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS


class GoogleClient

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize
    client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
    token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
    authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
    user_id = "default"
    credentials = authorizer.get_credentials user_id
    if credentials.nil?
      url = authorizer.get_authorization_url base_url: OOB_URI
      puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end

  # @param [String] spreadsheet_id
  def initialize(spreadsheet_id)
    # Initialize the API
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
    @spreadsheet_id = spreadsheet_id

  end


  def read_and_set_sended_every_row
    next_row = true
    start = 2
    while next_row
      range = "simulazione!A#{start}:N#{start}"
      response = @service.get_spreadsheet_values @spreadsheet_id, range
      if response.values.empty?
        next_row = false
      else

        dati = {
          chiave_ricerca: response.values.first[0],
          pagine_gialle: response.values.first[1],
          azienda: response.values.first[2],
          indirizzo: response.values.first[3],
          cap: response.values.first[4],
          citta: response.values.first[5],
          telefono: response.values.first[6],
          fax: response.values.first[7],
          web: response.values.first[9],
          email: response.values.first[11],
          spedite: response.values.first[12],
          timestamp_spedizione: (DateTime.parse(response.values.first[13]) rescue nil)
        }

        result = yield OpenStruct.new(dati)

        if result
          values = response.values
          values[0][12] = "SI"
          values[0][13] = Time.now
          response.update!(values: values)
          @service.update_spreadsheet_value @spreadsheet_id, range, response, value_input_option: "RAW"
        end
        start+=1
      end

    end
  end

end
