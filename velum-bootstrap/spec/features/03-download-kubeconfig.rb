require "spec_helper"
require 'uri'
require 'yaml'
require 'openssl'
require 'net/http'

feature "Download Kubeconfig" do
  before(:each) do
    unless self.inspect.include? "User registers"
      login
    end
  end

  # Using append after in place of after, as recommended by
  # https://github.com/mattheworiordan/capybara-screenshot#common-problems
  append_after(:each) do
    Capybara.reset_sessions!
  end

  scenario "User downloads the kubeconfig file" do
    with_status_ok do
      visit "/"
    end

    expect(page).to have_text("You currently have no nodes to be accepted for bootstrapping", wait: 240)

    puts ">>> User clicks to download kubeconfig"
    expect(page).to have_text("kubeconfig")
    with_screenshot(name: :download_kubeconfig) do
      click_on "kubeconfig"
    end
    puts "<<< User clicks to download kubeconfig"

    puts ">>> User logs in to Dex"
    expect(page).to have_text("Log in to Your Account")
    with_screenshot(name: :oidc_login) do
      fill_in "login", with: "test@test.com"
      fill_in "password", with: "password"
      click_button "Login"
    end
    puts "<<< User logs in to Dex"

    puts ">>> User is redirected back to velum"
    expect(page).to have_text("You will see a download dialog")
    puts "<<< User is redirected back to velum"

    puts ">>> User sees a download button to download file if neeeded"
    expect(page).to have_text("Click here if the download has not started automatically.")
    puts "<<< User sees a download button to download file if neeeded"

    puts ">>> User is prompted to download the kubeconfig"
    content_disposition = page.response_headers["Content-Disposition"]
    expect(content_disposition).to eq("attachment; filename=kubeconfig")
    puts "<<< User is prompted to download the kubeconfig"

    # poltergeist doesn't download the file itself so we need to download
    # the file manually in order to make the other tests pass
    download_kubeconfig
  end
end
