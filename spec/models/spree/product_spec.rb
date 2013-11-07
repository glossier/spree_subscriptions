require 'spec_helper'

describe Spree::Product do
  include ProductMacros

  before do
    setup_subscribable_products
  end
  let(:simple_product) { Factory(:simple_product) }

  it 'should respond to subscribable' do
    @product.should respond_to :subscribable?
  end

  it "should be subscribable" do
    @product.reload.subscribable?.should be_true
  end

  it "should have subscribable to false by default" do
    simple_product.subscribable?.should be false
  end 

  it "should return a list of subscribable variants" do
    @product.reload.subscribable_variants.map(&:sku).should == ['subscribable']
  end

end
