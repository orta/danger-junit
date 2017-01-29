require File.expand_path('../spec_helper', __FILE__)

#
module Danger
  describe Danger::DangerJunit do
    it 'should be a plugin' do
      expect(Danger::DangerJunit.new(nil)).to be_a Danger::Plugin
    end

    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @junit = @dangerfile.junit
      end

      it 'gets the right results for the eigen failure' do
        @junit.parse 'spec/fixtures/eigen_fail.xml'

        expect(@junit.failures.count).to eq 2
        expect(@junit.passes.count).to eq 1109
        expect(@junit.errors.count).to eq 0
        expect(@junit.skipped.count).to eq 0
      end

      it 'gets the right results for the selenium failure' do
        @junit.parse 'spec/fixtures/selenium.xml'

        expect(@junit.failures.count).to eq 1
        expect(@junit.passes.count).to eq 0
        expect(@junit.errors.count).to eq 0
        expect(@junit.skipped.count).to eq 0
      end

      it 'gets the right results for trainer generated files' do
        @junit.parse 'spec/fixtures/fastlane_trainer.xml'

        expect(@junit.failures.count).to eq 1
        expect(@junit.passes.count).to eq 1
        expect(@junit.errors.count).to eq 0
        expect(@junit.skipped.count).to eq 0
      end

      it 'gets the right results for the danger rspec failure' do
        @junit.parse 'spec/fixtures/rspec_fail.xml'

        expect(@junit.failures.count).to eq 1
        expect(@junit.passes.count).to eq 190
        expect(@junit.errors.count).to eq 0
        expect(@junit.skipped.count).to eq 7
      end

      it 'shows a known markdown row' do
        @junit.parse 'spec/fixtures/rspec_fail.xml'
        @junit.report

        output = @junit.status_report[:markdowns].first
        row = '| Danger::CISource::CircleCI validates when circle all env vars are set | ./spec/lib/danger/ci_sources/circle_spec.rb | 0.012097|'
        expect(output.to_s).to include(row)
      end

      it 'shows a known markdown row' do
        @junit.parse 'spec/fixtures/rspec_fail.xml'
        @junit.headers = [:time]
        @junit.report

        output = @junit.status_report[:markdowns].first
        row = "Time|\n"
        expect(output.to_s).to include(row)
      end

      it 'shows a warning for skipped' do
        @junit.parse 'spec/fixtures/rspec_fail.xml'
        @junit.show_skipped_tests = true
        @junit.report

        warnings = @junit.status_report[:warnings].first
        expect(warnings).to eq('Skipped 7 tests.')
      end

      it 'links paths that are files' do
        allow(@dangerfile.github).to receive(:pr_json).and_return('head' => { 'repo' => { 'html_url' => 'https://github.com/thing/thingy' } })
        allow(@dangerfile.github).to receive(:head_commit).and_return('hello')

        @junit.parse 'spec/fixtures/danger-junit-fail.xml'
        @junit.report

        outputs = @junit.status_report[:markdowns].first
        expect(outputs.to_s).to include('github.com/thing/thingy')
      end
    end
  end
end
