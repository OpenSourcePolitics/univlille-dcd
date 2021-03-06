# frozen_string_literal: true

require "spec_helper"

def fill_registration_form
  fill_in :registration_user_name, with: "Nikola Tesla"
  fill_in :registration_user_nickname, with: "the-greatest-genius-in-history"
  fill_in :registration_user_email, with: "nikola.tesla@example.org"
  fill_in :registration_user_password, with: "sekritpass123"
  fill_in :registration_user_password_confirmation, with: "sekritpass123"
end

describe "Registration", type: :system do
  let(:organization) { create(:organization) }
  let!(:terms_and_conditions_page) { Decidim::StaticPage.find_by(slug: "terms-and-conditions", organization: organization) }
  let!(:students_scope_1) { create(:scope, organization: organization, code: "SE-1") }
  let!(:students_scope_2) { create(:scope, organization: organization, code: "SE-2") }
  let!(:teacher_scope_1) { create(:scope, organization: organization, code: "ST-1") }
  let!(:teacher_scope_2) { create(:scope, organization: organization, code: "ST-2") }
  let!(:personal_scope_1) { create(:scope, organization: organization, code: "SP-1") }
  let!(:personal_scope_2) { create(:scope, organization: organization, code: "SP-2") }
  let!(:scope) { create(:scope, organization: organization) }

  before do
    switch_to_host(organization.host)
    visit decidim.new_user_registration_path
  end

  context "when signing up" do
    describe "on first sight" do
      it "shows fields empty" do
        expect(page).to have_content("Sign up to participate")
        expect(page).to have_field("registration_user_name", with: "")
        expect(page).to have_field("registration_user_nickname", with: "")
        expect(page).to have_field("registration_user_email", with: "")
        expect(page).to have_field("registration_user_password", with: "")
        expect(page).to have_field("registration_user_password_confirmation", with: "")
        expect(page).to have_field("registration_user_newsletter", checked: false)
        expect(page).to have_field("registration_user_status_student", checked: false)
        expect(page).to have_field("registration_user_status_personal", checked: false)
        expect(page).to have_field("registration_user_status_teacher", checked: false)
        expect(page).to have_field("registration_user_status_partner", checked: false)
      end

      it "hides provenance select" do
        expect(page).to have_css("#registration_user_provenance", visible: :hidden)
      end

      context "when users choose a status" do
        shared_examples_for "choose registration status" do |status, visibility|
          it "shows the provenance dropdown for status '#{status}'" do
            choose("user[status]", option: status)

            expect(page).to have_css("#registration_user_provenance", visible: visibility)
          end
        end

        it_behaves_like "choose registration status", "student"
        it_behaves_like "choose registration status", "teacher"
        it_behaves_like "choose registration status", "personal"
        it_behaves_like "choose registration status", "partner", :hidden

        context "when provenance list has options for selected status" do
          shared_examples_for "options lists related to status" do |status|
            it "shows the provenance dropdown" do
              choose("user[status]", option: status)

              within "#registration_user_provenance" do
                expect(page).to have_css("option[data-status='student']", visible: :visible)
                expect(page).to have_css("option[data-status='#{status}']", visible: :visible)
              end
            end
          end

          it_behaves_like "options lists related to status", "student"
          it_behaves_like "options lists related to status", "personal"

          it "shows the provenance dropdown for status teacher" do
            choose("user[status]", option: "teacher")

            within "#registration_user_provenance" do
              expect(page).to have_css("option[data-status='student']", visible: :visible)
              expect(page).to have_css("option[data-status='teacher']", visible: :visible)
              expect(page).to have_css("option[data-status='personal']", visible: :visible)
            end
          end

          context "and selecting a provenance" do
            it "is valid" do
              fill_registration_form

              choose("I am a student")
              select students_scope_1.name["en"]

              find(:css, "#registration_user_tos_agreement").set(true)
              find(:css, "#registration_user_rgpd_agreement").set(true)
              within "form.new_user" do
                find("*[type=submit]").click
              end

              click_button "Keep uncheck"
              expect(page).to have_content("You have signed up successfully")
            end
          end
        end
      end
    end
  end

  context "when newsletter checkbox is unchecked" do
    it "opens modal on submit" do
      within "form.new_user" do
        find("*[type=submit]").click
      end
      expect(page).to have_css("#sign-up-newsletter-modal", visible: :visible)
      expect(page).to have_current_path decidim.new_user_registration_path
    end

    it "checks when clicking the checking button" do
      within "form.new_user" do
        find("*[type=submit]").click
      end
      click_button "Check and continue"
      expect(page).to have_current_path decidim.new_user_registration_path
      expect(page).to have_css("#sign-up-newsletter-modal", visible: :hidden)
      expect(page).to have_field("registration_user_newsletter", checked: true)
    end

    it "submit after modal has been opened and selected an option" do
      within "form.new_user" do
        find("*[type=submit]").click
      end
      click_button "Keep uncheck"
      expect(page).to have_css("#sign-up-newsletter-modal", visible: :all)
      fill_registration_form
      within "form.new_user" do
        find("*[type=submit]").click
      end
      expect(page).to have_current_path decidim.user_registration_path
      expect(page).to have_field("registration_user_newsletter", checked: false)
    end
  end

  context "when newsletter checkbox is checked but submit fails" do
    before do
      fill_registration_form
      page.check("registration_user_newsletter")
    end

    it "keeps the user newsletter checkbox true value" do
      within "form.new_user" do
        find("*[type=submit]").click
      end
      expect(page).to have_current_path decidim.user_registration_path
      expect(page).to have_field("registration_user_newsletter", checked: true)
    end
  end
end
