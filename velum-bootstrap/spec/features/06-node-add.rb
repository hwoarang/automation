require "spec_helper"
require "yaml"

feature "Add a Node" do
  before do
    login
  end

  # Using append after in place of after, as recommended by
  # https://github.com/mattheworiordan/capybara-screenshot#common-problems
  append_after do
    Capybara.reset_sessions!
  end

  scenario "User accepts new nodes" do
    with_status_ok do
      visit "/"
    end

    puts ">>> Checking if new nodes appeared"
    with_screenshot(name: :new_nodes_appearance) do
      within(".pending-nodes-container") do
        expect(page).to have_button("accept-all", wait: 720)
      end
    end
    puts "<<< New nodes have appeared"

    puts ">>> Click to accept all minion keys"
    with_screenshot(name: :accept_button_click) do
      click_button("accept-all")
    end

    puts ">>> Waiting 120 seconds as a workaround"
    # ugly workaround for https://bugzilla.suse.com/show_bug.cgi?id=1050450
    # FIXME: drop it when bug is fixed
    sleep 120
    puts "<<< Waiting 120 seconds as a workaround"

    # wait for new link to appear
    puts ">>> Wait for new-node link to be enabled"
    with_screenshot(name: :new_node_link_enabled) do
      expect(page).to have_link(class: "assign-nodes-link", wait: 120)
    end
    puts "<<< new node link enabled"

    with_status_ok do
      visit "/assign_nodes"
    end

    puts ">>> Waiting for page to settle"
    with_screenshot(name: :wait_for_settle_new_nodes) do
      expect(page).not_to have_text("Loading...", wait: 20)
    end
    puts "<<< Page has settled"

    new_nodes_count = node_number
    puts ">>> Selecting minion roles"
    with_screenshot(name: :select_new_minion_roles) do
      environment["minions"].each do |minion|
        # skip all minions that have been assigned already
        unless page.text.include? minion["minionId"]
          new_nodes_count -= 1
          next
        end
        next unless %w[master worker].include?(minion["role"])
        within("tr", text: minion["minionId"]) do
          find(".#{minion["role"]}-btn").click
        end
      end
    end

    puts ">>> Wait for Add nodes button to be enabled"
    with_screenshot(name: :add_nodes_button_enabled) do
      expect(page).to have_css(".add-nodes-btn", wait: 20)
    end
    puts "<<< Add nodes button enabled"

    puts ">>> click to add node"
    with_screenshot(name: :select_new_nodes_role) do
      find(".add-nodes-btn").click
    end
    puts "<<< clicked add node"

    orch_timeout = [[3600, new_nodes_count * 120].max, 7200].min
    puts ">>> Wait until node add orchestration is complete (Timeout: #{orch_timeout})"
    with_screenshot(name: :node_add_orchestration_complete) do
      within(".nodes-container") do
        expect(page).to have_css(".fa-check-circle-o, .fa-times-circle",
                                  count: node_number, wait: orch_timeout)
      end
    end
    puts "<<< Node add orchestration completed"

    puts ">>> Checking if node add orchestration succeeded"
    with_screenshot(name: :node_add_orchestration_succeeded) do
      within(".nodes-container") do
        expect(page).to have_css(".fa-check-circle-o", count: node_number, wait: 5)
      end
    end
    puts "<<< Node add orchestration succeeded"
  end
end
