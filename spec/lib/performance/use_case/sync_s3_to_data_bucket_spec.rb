require_relative "../metrics/s3_fake_client"
describe Performance::UseCase::SyncS3ToDataBucket do
  subject do
    described_class.new(
      s3_gateway:,
      dest_bucket:,
      dest_key:,
    )
  end

  let(:s3_gateway) { Performance::Gateway::S3.new("prefix", source_bucket) }
  let(:source_bucket) { "source-bucket" }
  let(:dest_bucket) { "dest-bucket" }
  let(:dest_key) { "dest-key" }
  let(:s3_client) { Performance::Metrics.fake_s3_client }

  before do
    allow(Services).to receive(:s3_client).and_return s3_client
  end

  context "when S3 has valid data" do
    let(:data) do
      [
        { "a" => 1, "b" => 2 },
        { "c" => 3, "d" => 4 },
      ]
    end

    before do
      s3_client.put_object(bucket: source_bucket, key: "prefix/one", body: data[0].to_json)
      s3_client.put_object(bucket: source_bucket, key: "prefix/two", body: data[1].to_json)
      subject.execute
    end

    it "writes all data records to the destination bucket" do
      response = s3_client.get_object(bucket: dest_bucket, key: dest_key)
      expect(JSON.parse(response.body.read)).to match_array(data)
    end
  end

  context "when S3 contains empty or nil data" do
    before do
      s3_client.put_object(bucket: source_bucket, key: "prefix/one", body: { a: 1 }.to_json)
      s3_client.put_object(bucket: source_bucket, key: "prefix/two", body: "") # empty string
      s3_client.put_object(bucket: source_bucket, key: "prefix/three", body: nil) # nil body
      subject.execute
    end

    it "skips empty or nil data and writes only valid records" do
      response = s3_client.get_object(bucket: dest_bucket, key: dest_key)
      parsed = JSON.parse(response.body.read)
      expect(parsed).to eq([{ "a" => 1 }])
    end
  end
end
