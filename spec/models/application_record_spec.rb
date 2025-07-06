require "rails_helper"

RSpec.describe ApplicationRecord, type: :model do
  it "is an abstract class" do
    expect(described_class.abstract_class).to be true
  end

  it "inherits from ActiveRecord::Base" do
    expect(described_class.superclass).to eq(ActiveRecord::Base)
  end

  it "is used as base for other models" do
    expect(User.superclass).to eq(described_class)
    expect(Stream.superclass).to eq(described_class)
  end
end
