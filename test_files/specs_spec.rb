require 'rails_helper'

describe AdRollConfiguration do
  let(:store) { FactoryGirl.create(:store) }
  subject { FactoryGirl.create(:ad_roll_configuration, ad_roll_organization: nil, store: store) }

  before do
    allow_any_instance_of(AdRoll::Api::Advertisable).to receive(:get)
  end

  describe 'before_update' do
    context 'when updating budget' do
      it 'updates monthly_budget' do
        subject.update(max_advertisable_budget: 100)
        expect(subject.max_advertisable_monthly_budget).to eq(435.71)
      end
    end

    context 'when updating monthly_budget' do
      it 'updates budget' do
        subject.update(max_advertisable_monthly_budget: 436.00)
        expect(subject.max_advertisable_budget).to eq(100.07)
      end
    end

    context 'when updating budget AND monthly budget' do
      context 'when using pre UC campaigns' do
        it 'should update monthly_budget to match budget' do
          subject.update_attributes(
            max_advertisable_budget: 100,
            max_advertisable_monthly_budget: 436
          )
          expect(subject.max_advertisable_budget).to eq(100)
          expect(subject.max_advertisable_monthly_budget).to eq(435.71)
        end
      end
      context 'when using UC campaigns' do
        before { allow_any_instance_of(Store).to receive(:can_use_new_adroll?) { true } }
        it 'should update budget to match monthly_budget' do
          subject.update_attributes(
            max_advertisable_budget: 100.00,
            max_advertisable_monthly_budget: 436.00
          )
          expect(subject.max_advertisable_budget).to eq(100.07)
          expect(subject.max_advertisable_monthly_budget).to eq(436.00)
        end
      end
    end
  end

  describe "after_save" do
    context 'when optin in prospecting' do
      before do
        allow_any_instance_of(AdRollRemote).to receive(:optin_prospecting).and_return({ 'is_coop_approved' => true })
      end

      it 'makes API call to opt in to prospecting' do
        expect_any_instance_of(AdRollRemote).to receive(:optin_prospecting)
        subject.update(prospecting_optedin: true)
      end
    end
  end

  describe 'after_create' do
    subject { FactoryGirl.create(:ad_roll_configuration, :with_web_dynamic_templates, ad_roll_organization: nil) }

    before do
      allow_any_instance_of(AdRollRemote::DynamicTemplates)
        .to receive(:get_list_of_dynamic_templates)
        .and_return(template_list_response)
    end

    let(:template_list_response) do
      [
        {
          "category": nil,
          "is_visible": true,
          "allowed_advertisables": [],
          "name": "Product Gladiator",
          "in_testing": false,
          "capabilities": [
            {
              "is_enabled": true,
              "description": "Sale price",
              "eid": "RJTMLC5L4ZDVFJSGV3EMOJ",
              "type": nil,
              "id": 2,
              "name": "salePrice"
            }
          ],
          "eid": "GYV4ZCRXCZBQZLRTSEMANK",
          "id": 64,
          "is_private": false,
          "is_published": true
        },
        {
          "category": nil,
          "is_visible": true,
          "allowed_advertisables": [],
          "name": "Valentine Spotlight",
          "in_testing": false,
          "capabilities": [
            {
              "is_enabled": true,
              "description": "Sale price",
              "eid": "RJTMLC5L4ZDVFJSGV3EMOJ",
              "type": nil,
              "id": 2,
              "name": "salePrice"
            }
          ],
          "eid": "5VLPABPQ3RE3NNJTFKKQL3",
          "id": 45,
          "is_private": false,
          "is_published": true
        }
      ]
    end

    it 'gets web dynamic templates' do
      expect(subject.web_dynamic_template_capabilities).to eq(template_list_response)
    end

    it 'actually saves it' do
      subject.reload
      expect(subject.web_dynamic_template_capabilities).to eq(template_list_response)
    end
  end

  describe '#populate_web_dynamic_templates' do
    let(:template_list_response) do
      [
        {
          "category": nil,
          "is_visible": true,
          "allowed_advertisables": [],
          "name": "Product Gladiator",
          "in_testing": false,
          "capabilities": [
            {
              "is_enabled": true,
              "description": "Sale price",
              "eid": "RJTMLC5L4ZDVFJSGV3EMOJ",
              "type": nil,
              "id": 2,
              "name": "salePrice"
            }
          ],
          "eid": "GYV4ZCRXCZBQZLRTSEMANK",
          "id": 64,
          "is_private": false,
          "is_published": true
        },
        {
          "category": nil,
          "is_visible": true,
          "allowed_advertisables": [],
          "name": "Valentine Spotlight",
          "in_testing": false,
          "capabilities": [
            {
              "is_enabled": true,
              "description": "Sale price",
              "eid": "RJTMLC5L4ZDVFJSGV3EMOJ",
              "type": nil,
              "id": 2,
              "name": "salePrice"
            }
          ],
          "eid": "5VLPABPQ3RE3NNJTFKKQL3",
          "id": 45,
          "is_private": false,
          "is_published": true
        }
      ]
    end

    before do
      allow_any_instance_of(AdRollRemote).to receive(:get_list_of_dynamic_templates)
                                               .and_return(template_list_response)
    end

    it 'sets the template list response to the configuration' do
      subject.populate_web_dynamic_templates
      expect(subject.web_dynamic_template_capabilities).to eq(template_list_response)
    end
  end

  describe 'ensure_checkout_url' do
    context 'when ensuring checkout_url is not set' do
      it 'uses the default value' do
        expect(subject.checkout_url).to eq('*/success*')
      end
    end
  end

  describe '#setup_completion_stage' do
    context 'when ad_roll_configuration is submitted' do
      context 'when facebook_page_url is blank' do
        before do
          subject.update_attributes(facebook_page_url: nil, submitted: true)
        end

        it 'returns hash for Process Complete' do
          expect(subject.setup_completion_stage).to match({ value: 100, text: 'Process Complete' })
        end
      end

      context 'when facebook_page_url is present' do
        context ' when Facebook is authorized' do
          before do
            subject.update_attributes(facebook_page_url: 'www.facebook.com/page', submitted: true)
            allow(subject).to receive_message_chain(:remote, :authorize_facebook).and_return(true)
          end

          it 'returns hash for Process Complete' do
            expect(subject.setup_completion_stage).to match({ value: 100, text: 'Process Complete' })
          end
        end

        context 'when Facebook is not authorized' do
          before do
            subject.update_attributes(facebook_page_url: 'www.facebook.com/page', submitted: true)
            allow(subject).to receive_message_chain(:remote, :authorize_facebook).and_return(false)
          end

          it 'returns hash for Facebook Not Authorized' do
            expect(subject.setup_completion_stage).to match({ value: 90, text: 'Facebook Not Authorized' })
          end
        end
      end
    end
  end

  specify 'pixel_script does not contain type 39 characters' do
    subject.pixel_script = '&#39; gsub'
    subject.pixel_script.should eq('&#34; gsub')
  end

  describe '#set_ad_roll_organization' do
    context 'when multiple AdRollOrganizations are present' do
      let!(:first_org) { AdRollOrganization.create(username: 'org1@springbot.com', password: 'easy', organization_eid: '1') }
      let!(:last_org) { AdRollOrganization.create(username: 'org1@springbot.com', password: 'easy', organization_eid: '2') }

      it 'sets ad_roll_organzation to the most recently created one' do
        expect(subject.ad_roll_organization_id).to eq(last_org.id)
      end
    end

    context 'when an AdRollOrganization is not present' do
      it 'does nothing' do
        expect(subject.ad_roll_organization_id).to be_nil
      end
    end
  end

  describe '#extract_pixel_eid' do
    let(:pixel_eid) { 'WOOOOTIMAPIXELEID' }
    let(:pixel_script) { "&lt;script type=&quot;text/javascript&quot;&gt;\nadroll_adv_id = &quot;ADVID&quot;;\nadroll_pix_id = &quot;#{pixel_eid}&quot;;\n(function () {\nvar oldonload = window.onload;\nwindow.onload = function(){\n   __adroll_loaded=true;\n   var scr = document.createElement(&quot;script&quot;);\n   var host = ((&quot;https:&quot; == document.location.protocol) ? &quot;https://s.adroll.com&quot; : &quot;http://a.adroll.com&quot;);\n   scr.setAttribute('async', 'true');\n   scr.type = &quot;text/javascript&quot;;\n   scr.src = host + &quot;/j/roundtrip.js&quot;;\n   ((document.getElementsByTagName('head') || [null])[0] ||\n    document.getElementsByTagName('script')[0].parentNode).appendChild(scr);\n   if(oldonload){oldonload()}};\n}());\n&lt;/script&gt;\n" }
    let(:extracted_pixel_eid) { subject.extract_pixel_eid }

    before do
      subject.pixel_script = pixel_script
    end

    it 'returns the extracted pixel eid' do
      expect(extracted_pixel_eid).to eq pixel_eid
    end

    context 'when script is nil' do
      let(:pixel_script) { nil }

      it 'returns nil' do
        expect(extracted_pixel_eid).to be_nil
      end
    end

    context 'when script is malformed' do
      let(:pixel_script) { '<p>IMANAWFULPIXELSCRIPT</p>' }

      it 'returns nil' do
        expect(extracted_pixel_eid).to be_nil
      end
    end
  end

  describe '#pixel_eid' do
    let(:advertisable_eid) { Faker::Internet.password }
    let!(:organization) { FactoryGirl.create(:ad_roll_organization) }

    let(:response_body) do
      {
        'results' => {
          'status' => 'dropped',
          'code' => '&lt;script type=&#34;text/javascript&#34;&gt;\n    adroll_adv_id = &#34;22D7TY4FT5HBJE54JKRM6J&#34;;\n    adroll_pix_id = &#34;SO57LYU4UFHKTIHOUWMFNM&#34;;\n    // adroll_email = &#34;username@example.com&#34;; // OPTIONAL: provide email to improve user identification\n    (function () {\n        var _onload = function(){\n            if (document.readyState &amp;&amp; !/loaded|complete/.test(document.readyState)){setTimeout(_onload, 10);return}\n            if (!window.__adroll_loaded){__adroll_loaded=true;setTimeout(_onload, 50);return}\n            var scr = document.createElement(&#34;script&#34;);\n            var host = ((&#34;https:&#34; == document.location.protocol) ? &#34;https://s.adroll.com&#34; : &#34;http://a.adroll.com&#34;);\n            scr.setAttribute(&#39;async&#39;, &#39;true&#39;);\n            scr.type = &#34;text/javascript&#34;;\n            scr.src = host + &#34;/j/roundtrip.js&#34;;\n            ((document.getElementsByTagName(&#39;head&#39;) || [null])[0] ||\n                document.getElementsByTagName(&#39;script&#39;)[0].parentNode).appendChild(scr);\n        };\n        if (window.addEventListener) {window.addEventListener(&#39;load&#39;, _onload, false);}\n        else {window.attachEvent(&#39;onload&#39;, _onload)}\n    }());\n&lt;/script&gt;\n',
          'eid' => 'SO57LYU4UFHKTIHOUWMFNM',
          'is_consistent' => true
        }
      }
    end

    before do
      subject.ad_roll_organization = organization
      subject.advertisable_eid = advertisable_eid

      allow_any_instance_of(AdRoll::Api::Advertisable).to receive(:get_pixel)
                                                            .and_return(response_body)
    end

    it { expect(subject.pixel_eid).to eq 'SO57LYU4UFHKTIHOUWMFNM' }

    context 'when the results are empty' do
      let(:response_body) { nil }

      it { expect(subject.pixel_eid).to be_nil }
    end
  end

  describe '#cache_date_report' do
    let(:date) { Date.current }

    before do
      allow_any_instance_of(AdRollRemote).to receive(:advertisable_attributions).and_return([])
      allow_any_instance_of(AdRollRemote).to receive(:advertisable_deliveries).and_return([])
    end

    it 'upserts an AdRollDateReport for each date' do
      expect(AdRollDateReport).to receive(:upsert_report).with(subject.store_id,
                                                               subject.advertisable_eid,
                                                               AdRollDateReport::ADVERTISABLE,
                                                               date,
                                                               nil,
                                                               nil)
      subject.cache_date_report(date, date)
    end
  end

  describe '#total_budget' do
    context 'when max_advertisable_budget is set' do
      before do
        subject.max_advertisable_budget = 200
      end

      it 'returns the max_advertisable_budget' do
        expect(subject.total_budget).to eq 200
      end
    end

    context 'when max_advertisable_budget is not set' do
      context 'when store has adroll fee enabled' do
        before {
          allow_any_instance_of(Store).to receive(:ad_roll_fee_enabled?) { true }
        }
        it 'returns the new default max' do
          expect(subject.total_budget).to eq AdRollConfiguration::NEW_DEFAULT_MAX_WEEKLY_BUDGET
        end
      end
      it 'returns the old default max' do
        expect(subject.total_budget).to eq AdRollConfiguration::OLD_DEFAULT_MAX_WEEKLY_BUDGET
      end
    end
  end

  describe '#total_monthly_budget' do
    context 'when max_advertisable_budget is set' do
      before do
        subject.max_advertisable_monthly_budget = 200
      end

      it 'returns the max_advertisable_budget' do
        expect(subject.total_monthly_budget).to eq 200
      end
    end

    context 'when max_advertisable_budget is not set' do
      it 'returns the default max' do
        expect(subject.total_monthly_budget).to eq(subject.default_max_monthly_budget)
      end
    end
  end

  describe '#total_allocated_budget' do
    let!(:campaigns) { FactoryGirl.create_list :ad_roll_campaign, 3, store_id: store.id, budget: 5 }
    let!(:bad_campaign) { FactoryGirl.create :ad_roll_campaign, store_id: store.id, budget: 5, status: 'paused' }

    it 'returns the total budget allocated' do
      expect(subject.total_allocated_budget).to eq 15
    end
  end

  describe '#total_allocated_monthly_budget' do
    let!(:campaigns) { FactoryGirl.create_list :ad_roll_campaign, 3, store_id: store.id, budget: 5, monthly_budget: 22 }
    let!(:bad_campaign) { FactoryGirl.create :ad_roll_campaign, store_id: store.id, budget: 5, monthly_budget: 22, status: 'paused' }

    it 'returns the total budget allocated' do
      expect(subject.total_allocated_monthly_budget).to eq 66
    end
  end

  describe '#total_allocated_budget_percentage' do
    let!(:campaigns) { FactoryGirl.create_list :ad_roll_campaign, 3, store_id: store.id, budget: 5 }
    let!(:bad_campaign) { FactoryGirl.create :ad_roll_campaign, store_id: store.id, budget: 5, status: 'paused' }

    before do
      subject.update_max_monthly_budget
    end

    it 'returns the total budget allocated as a percentage' do
      expect(subject.total_allocated_budget_percentage).to eq 45
    end
  end

  describe 'max_advertisable_monthly_budget' do
    context 'when monthly budget is nil' do
      before do
        subject.max_advertisable_budget = 23
        subject.max_advertisable_monthly_budget = nil
      end

      it 'should update and get a number' do
        expect(subject.max_advertisable_monthly_budget).to eq(100.21)
      end
    end

    context 'when monthly budget is a float' do
      before do
        subject.max_advertisable_budget = 100
        subject.max_advertisable_monthly_budget = 435.72
      end

      it "should return it's value" do
        expect(subject.max_advertisable_monthly_budget).to eq(435.72)
      end
    end
  end

  describe 'monthly_budget_accurate?' do
    context 'when max_advertisable_monthly_budget is nil' do
      subject { described_class.new }

      it 'returns falsy' do
        expect(subject.monthly_budget_accurate?).to be_falsy
      end
    end

    context 'when max_advertisable_monthly_budget is accurate' do
      before do
        subject.max_advertisable_budget = 688.52
        subject.max_advertisable_monthly_budget = 3000
      end

      it 'returns truthy' do
        expect(subject.monthly_budget_accurate?).to be_truthy
      end
    end

    context 'max_advertisable_monthly_budget is inaccurate' do
      before do
        subject.max_advertisable_budget = 688.52
        subject.max_advertisable_monthly_budget = 5
      end

      it 'returns falsy' do
        expect(subject.monthly_budget_accurate?).to be_falsy
      end
    end
  end

  describe '#update_max_monthly_budget' do
    before do
      subject.max_advertisable_budget = 22.9
    end

    it 'returns accurate number' do
      subject.update_max_monthly_budget
      expect(subject.max_advertisable_monthly_budget).to eq(99.78)
    end
  end

  describe '#default_conversion_rule_pattern for Shopify' do
    before do
      store.plugin_version = '0.0.5.100'
    end

    it 'returns the correct default conversion url' do
      expect(subject.default_conversion_rule_pattern).to eq '*/checkouts/*/thank_you*'
    end
  end

  describe '#default_conversion_rule_pattern for Magento2' do
    before do
      store.plugin_version = '0.0.5.200'
    end

    it 'returns the correct default conversion url' do
      expect(subject.default_conversion_rule_pattern).to eq '*/success*'
    end
  end

  describe '#default_conversion_rule_pattern for BigCommerce' do
    before do
      store.plugin_version = '0.0.5.300'
    end

    it 'returns the correct default conversion url' do
      expect(subject.default_conversion_rule_pattern).to eq '*/order-confirmation*'
    end
  end

  describe '#default_conversion_rule_pattern for WooCommerce' do
    before do
      store.plugin_version = '0.0.5.400'
    end

    it 'returns the correct default conversion url' do
      expect(subject.default_conversion_rule_pattern).to eq '*/checkout/order-received/*'
    end
  end

  describe '#store_locale' do
    context 'When store currency is USD' do
      before do
        allow_any_instance_of(Store).to receive(:store_currency_code).and_return('USD')
      end

      it 'returns USA locale' do
        expect(subject.store_locale).to eq('en_US')
      end
    end

    context 'When store currency is GBP' do
      before do
        allow_any_instance_of(Store).to receive(:store_currency_code).and_return('GBP')
      end

      it 'returns Great Britain locale' do
        expect(subject.store_locale).to eq('en_GB')
      end
    end

    context 'When store currency is EUR' do
      before do
        allow_any_instance_of(Store).to receive(:store_currency_code).and_return('EUR')
      end

      it 'returns French locale' do
        expect(subject.store_locale).to eq('fr_FR')
      end
    end

    context 'Default' do
      before do
        allow_any_instance_of(Store).to receive(:store_currency_code).and_return('KRW')
      end

      it 'defaults to USD' do
        expect(subject.store_locale).to eq('en_US')
      end
    end
  end

  describe "ad_roll_fee_configuration" do
    let!(:store) { FactoryGirl.create(:store) }
    let!(:global_config) { FactoryGirl.create(:ad_roll_fee_configuration, global: true) }
    let!(:subject) { FactoryGirl.create(:ad_roll_configuration, store: store) }
    context 'when subject has no ad_roll_fee_configuration' do
      context 'when store has ad roll fee enabled' do
        let!(:store) { FactoryGirl.create(:store, ad_roll_fee_enabled: "1") }
        it 'returns the global configuration' do
          expect(global_config).to be_valid
          expect(subject.ad_roll_fee_configuration).to eq(global_config)
        end
      end
    end
    context 'when subject has an ad_roll_fee_configuration' do
      let!(:attached_fee_config) { FactoryGirl.create(:ad_roll_fee_configuration, global: false, ad_roll_configuration: subject, store: store) }
      it 'return the configuration' do
        expect(subject.ad_roll_fee_configuration).to eq(attached_fee_config)
      end
    end
  end

  describe "percent_fee" do
    let!(:global_fee_config) { FactoryGirl.create(:ad_roll_fee_configuration, global: true) }
    let(:ad_roll_fee_ranges) do
      [
        { fee: 0.00, fee_type: 'flat', min_monthly_budget: 0.00, max_monthly_budget: 174.99 },
        { fee: 25.00, fee_type: 'flat', min_monthly_budget: 175.00, max_monthly_budget: 500.00 },
        { fee: 0.25, fee_type: 'percent', min_monthly_budget: 500.01, max_monthly_budget: 1_000_000.00 }
      ]
    end
    before do
      ad_roll_fee_ranges.each do |range_data|
        FactoryGirl.create(:ad_roll_fee_range, ad_roll_fee_configuration: global_fee_config, **range_data)
      end
    end
    context 'when store has ad_roll_fee enabled' do
      before do
        allow(subject).to receive_message_chain(:store, :ad_roll_fee_enabled?) { true }
      end

      context "when range returns a flat fee" do
        it 'returns the percent fee calculated from the max_advertisable_monthly_budget' do
          subject.max_advertisable_monthly_budget = 175.00
          expect(subject.mgmt_fee_percent).to be_within(0.001).of(25.00 / 175.00)
          # note: when calculated from flat fee, percent_fee is NOT rounded for increased accuracy
        end
      end
      context 'when range returns a percent fee' do
        it 'returns the fee as a percent without calculation' do
          subject.max_advertisable_monthly_budget = 500.01
          expect(subject.mgmt_fee_percent).to eq(0.25)
        end
      end
    end
    context 'when store does not have ad_roll_fee enabled' do
      before do
        allow(subject).to receive_message_chain(:store, :ad_roll_fee_enabled?) { false }
      end
      context "when range returns a flat fee" do
        it 'returns the percent fee calculated from the max_advertisable_monthly_budget' do
          subject.max_advertisable_monthly_budget = 175.00
          expect(subject.mgmt_fee_percent).to eq(0.00)
        end
      end
      context 'when range returns a percent fee' do
        it 'returns the fee as a percent without calculation' do
          subject.max_advertisable_monthly_budget = 500.01
          expect(subject.mgmt_fee_percent).to eq(0.00)
        end
      end
    end
  end
end
