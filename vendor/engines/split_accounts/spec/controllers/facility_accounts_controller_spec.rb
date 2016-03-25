require "rails_helper"
require_relative "../split_accounts_spec_helper"

RSpec.describe FacilityAccountsController, :enable_split_accounts do
  render_views

  let(:facility) { FactoryGirl.create(:setup_facility) }
  before { sign_in user }

  shared_examples "allows editing" do
    describe "show" do
      let(:split_account) { FactoryGirl.create(:split_account) }

      before { get :show, facility_id: facility.url_name, id: split_account.id }

      it "includes edit button" do
        expect(response.body).to include("Edit")
      end
    end

    describe "edit" do
      let(:split_account) { FactoryGirl.create(:split_account) }
      before { get :edit, facility_id: facility.url_name, id: split_account.id }

      it "has only the description field", :aggregate_failures do
        expect(response.body).to include("Description")
        expect(response.body).not_to include("Account Number")
        expect(response.body).not_to include("Add another subaccount")
      end
    end

    describe "update" do
      let(:split_account) { FactoryGirl.create(:split_account) }
      before { post :update, facility_id: facility.url_name, id: split_account.id, split_accounts_split_account: { description: "New Description" } }

      it "updates the description" do
        expect(split_account.reload.description).to eq("New Description")
      end
    end
  end

  shared_examples "allows suspending" do
    let(:split_account) { FactoryGirl.create(:split_account) }

    describe "show" do
      before { get :show, facility_id: facility.url_name, id: split_account.id }

      it "includes the suspend button" do
        expect(response.body).to include("Suspend")
      end
    end

    describe "suspending" do
      it "suspends the account" do
        expect { get :suspend, facility_id: facility.url_name, id: split_account.id }
          .to change { split_account.reload.suspended_at }
      end
    end
  end

  describe "as an admin" do
    let(:user) { FactoryGirl.create(:user, :administrator) }

    include_examples "allows editing"
    include_examples "allows suspending"

    describe "default new" do
      before { get :new, facility_id: facility.url_name, owner_user_id: user.id }

      it "sees split account option", :aggregate_failures do
        expect(response.code).to eq("200")
        expect(response.body).to include("Chart String")
        expect(response.body).to include("Split Account")
      end
    end

    describe "new on split accounts" do
      before { get :new, facility_id: facility.url_name, owner_user_id: user.id, account_type: "SplitAccounts::SplitAccount" }

      it "renders successfully", :aggregate_failures do
        expect(response.code).to eq("200")
        expect(response.body).to include("Account Number")
        expect(response.body).to include("Add another subaccount")
      end

      it "assigns the correct type of account" do
        expect(assigns(:account)).to be_a(SplitAccounts::SplitAccount)
      end
    end
  end

  describe "as a facility admin" do
    let(:user) { FactoryGirl.create(:user, :facility_director, facility: facility) }

    include_examples "allows editing"
    include_examples "allows suspending"

    describe "default new" do
      before { get :new, facility_id: facility.url_name, owner_user_id: user.id }

      it "does not see split account option", :aggregate_failures do
        expect(response.code).to eq("200")
        expect(response.body).to include("Chart String")
        expect(response.body).not_to include("Split Account")
      end
    end

    describe "new on split accounts" do
      before { get :new, facility_id: facility.url_name, owner_user_id: user.id, account_type: "SplitAccounts::SplitAccount" }

      it "falls back to the default account type" do
        expect(assigns(:account)).to be_a(NufsAccount)
      end
    end
  end

  describe "as an account manager" do
    let(:user) { FactoryGirl.create(:user, :account_manager) }
    let(:facility) { Facility.cross_facility }
    include_examples "allows editing"

    describe "show" do
      let(:split_account) { FactoryGirl.create(:split_account) }

      before { get :show, facility_id: facility.url_name, id: split_account.id }

      it "does not show the suspend buttons" do
        expect(response.body).not_to include("Suspend")
      end
    end
  end

  describe "as a staff member" do
    let(:user) { FactoryGirl.create(:user, :staff, facility: facility) }

    describe "show" do
      let(:split_account) { FactoryGirl.create(:split_account) }

      before { get :show, facility_id: facility.url_name, id: split_account.id }

      it "does not show the edit/suspend buttons", :aggregate_failures do
        expect(response.body).not_to include("Edit")
        expect(response.body).not_to include("Suspend")
      end
    end

    describe "edit" do
      let(:split_account) { FactoryGirl.create(:split_account) }
      before { get :edit, facility_id: facility.url_name, id: split_account.id }

      it "returns a 403" do
        expect(response.code).to eq("403")
      end
    end

    describe "update" do
      let(:split_account) { FactoryGirl.create(:split_account) }
      before { post :update, facility_id: facility.url_name, id: split_account.id }

      it "returns a 403" do
        expect(response.code).to eq("403")
      end
    end
  end
end