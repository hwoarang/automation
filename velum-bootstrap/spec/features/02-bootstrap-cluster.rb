require "spec_helper"
require 'yaml'

feature "Boostrap cluster" do

  let(:node_number) { environment["minions"].count { |element| element["role"] != "admin" } }
  let(:hostnames) { environment["minions"].map { |m| m["fqdn"] if m["role"] != "admin" }.compact }

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

  # User registration and cluster configuration has already been done in 01-setup-velum.rb
  # After login we need to do the configure steps again to reach the minion discovery page

  scenario "User configures the cluster" do
    with_screenshot(name: :configure) do
      configure
    end
  end

  scenario "User accepts all minions" do
    visit "/setup/discovery"

    puts ">>> Wait until all minions are pending to be accepted"
    with_screenshot(name: :pending_minions) do
      expect(page).to have_selector("a", text: "Accept Node", count: node_number, wait: 400)
    end
    puts "<<< All minions are pending to be accepted"

    puts ">>> Wait for accept-all button to be enabled"
    with_screenshot(name: :accept_button_enabled) do
      expect(page).to have_button("accept-all", disabled: false, wait: 20)
    end
    puts "<<< accept-all button enabled"

    puts ">>> Click to accept all minion keys"
    with_screenshot(name: :accept_button_click) do
      click_button("accept-all")
    end

    # ugly workaround for https://bugzilla.suse.com/show_bug.cgi?id=1050450
    # FIXME: drop it when bug is fixed
    sleep 30
    visit "/setup/discovery"

    puts ">>> Wait until Minion keys are accepted by salt"
    with_screenshot(name: :accepted_keys) do
      expect(page).to have_css("input[name='roles[worker][]']", count: node_number, wait: 600)
    end
    puts "<<< Minion keys accepted in Velum"

    puts ">>> Waiting until Minions are accepted in Velum"
    with_screenshot(name: :accepted_minions) do
      expect(page).to have_text("#{node_number} nodes found", wait: 60)
    end
    puts "<<< Minions accepted in Velum"

    # They should also appear in the UI
    hostnames.each do |hostname|
      expect(page).to have_content(hostname)
    end
  end

  scenario "User selects minion roles and bootstraps the cluster" do
    visit "/setup/discovery"

    puts ">>> Waiting for page to settle"
    with_screenshot(name: :wait_for_settle) do
      expect(page).to have_text("You currently have no nodes to be accepted for bootstrapping", wait: 120)
    end
    puts "<<< Page has settled"

    puts ">>> Selecting minion roles"
    with_screenshot(name: :select_minion_roles) do
      environment["minions"].each do |minion|
        if ["master", "worker"].include?(minion["role"])
          within("tr", text: minion["minionId"] || minion["minionID"]) do
            find(".#{minion["role"]}-btn").click
          end
        end
      end
    end
    puts "<<< Minion roles selected"

    puts ">>> Waiting for page to settle"
    with_screenshot(name: :wait_for_settle) do
      expect(page).to have_no_css(".discovery-minimum-nodes-alert", wait: 30)
    end
    puts "<<< Page has settled"

    puts ">>> Bootstrapping cluster"
    with_screenshot(name: :bootstrap_cluster) do
      expect(page).to have_button(value: "Bootstrap cluster", disabled: false)
      click_on "Bootstrap cluster"
    end

    if node_number < 3
      # a modal with a warning will appear as we only have #{node_number} nodes
      with_screenshot(name: :cluster_too_small) do
        expect(page).to have_content("Cluster is too small")
        click_button "Proceed anyway"
      end
    end
    puts "<<< Cluster bootstrapped"

    puts ">>> Wait until UI is loaded"
    with_screenshot(name: :ui_loaded) do
      within(".nodes-container") do
        expect(page).to have_no_css(".nodes-loading", wait: 30)
        expect(page).to have_css(".fa-spin", count: node_number, wait: 120)
      end
    end
    puts "<<< UI loaded"

    puts ">>> Wait until orchestration is complete"
    with_screenshot(name: :orchestration_complete) do
      within(".nodes-container") do
        expect(page).to have_css(".fa-check-circle-o", count: node_number, wait: 1800)
      end
    end
    puts "<<< Orchestration completed"

    puts ">>> Download kubeconfig"
    with_screenshot(name: :download_kubeconfig) do
      data = page.evaluate_script("\
        function() {
          var url = window.location.protocol + '//' + window.location.host + '/kubectl-config';\
          var xhr = new XMLHttpRequest();\
          xhr.open('GET', url, false);\
          xhr.send(null);\
          return xhr.responseText;\
        }()
      ")
      File.write("kubeconfig", data)
    end
  end
end