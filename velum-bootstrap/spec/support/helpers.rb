# A module containing helper methods to create a testing environment
# for end to end tests.
module Helpers
  def with_screenshot(name:, &block)
    save_screenshot("screenshots/#{Time.now.to_i}_before_#{name}.png", full: true)
    yield
    save_screenshot("screenshots/#{Time.now.to_i}_after_#{name}.png", full: true)
  end

  def with_status_ok(&block)
    yield
    expect(page.status_code).to eq(200)
  end

  private

  def login
    puts ">>> User logs in"
    with_status_ok do
      visit "/users/sign_in"
    end

    fill_in "user_email", with: "test@test.com"
    fill_in "user_password", with: "password"
    click_on "Log in"
    puts "<<< User logged in"
  end

  def register
    puts ">>> Registering user"
    with_status_ok do
      visit "/users/sign_up"
    end

    fill_in "user_email", with: "test@test.com"
    fill_in "user_password", with: "password"
    fill_in "user_password_confirmation", with: "password"
    click_on "Create Admin"
    puts "<<< User registered"
  end

  def download_kubeconfig
    # TODO: remove in the future when POST gets deployed
    matches = page.html.match(/window\.location\.href = "(.*?)"/)

    download_uri = if matches.nil?
      URI(page.html.match(/action="(.*?)"/).captures[0])
    else
      URI(matches.captures[0])
    end

    http = Net::HTTP.new(download_uri.host, download_uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = if page.has_css?("form")
      Net::HTTP::Post.new(download_uri.request_uri)
    else
      # TODO: remove in the future when POST gets deployed
      Net::HTTP::Get.new(download_uri.request_uri)
    end
    response = http.request(request)

    File.write("kubeconfig", response.body)
  end

  def default_interface
    `awk '$2 == 00000000 { print $1 }' /proc/net/route`.strip
  end

  def default_ip_address
    `ip addr show #{default_interface} | awk '$1 == "inet" {print $2}' | cut -f1 -d/`.strip
  end

  def configure
    puts ">>> Setting up velum"
    with_status_ok do
      visit "/setup"
    end

    fill_in "settings_dashboard", with: environment["dashboardHost"] || default_ip_address
    if ENV.fetch("ENABLE_TILLER", false) == "true"
      check "settings[tiller]"
    else
      uncheck "settings[tiller]"
    end
    click_on "Next"
    puts "<<< Velum set up"
  end
end

RSpec.configure { |config| config.include Helpers, type: :feature }
