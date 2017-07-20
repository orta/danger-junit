module Danger
  # Report, or inspect any JUnit XML formatted test suite report.
  #
  # Testing frameworks have standardized on the JUnit XML format for
  # reporting results, this means that projects using Rspec, Jasmine, Mocha,
  # XCTest and more - can all use the same Danger error reporting. Perfect.
  #
  # You can see some examples on [this page from Circle CI](https://circleci.com/docs/test-metadata/)
  # and on this [project's README](https://github.com/orta/danger-junit.git) about how you
  # can add JUnit XML output for your testing projects.
  #
  # @example Parse the XML file, and let the plugin do your reporting
  #
  #          junit.parse "/path/to/output.xml"
  #          junit.report
  #
  # @example Let the plugin parse the XML file, and report yourself
  #
  #          junit.parse "/path/to/output.xml"
  #          fail("Tests failed") unless junit.failures.empty?
  #
  # @example Warn on a report about skipped tests
  #
  #          junit.parse "/path/to/output.xml"
  #          junit.show_skipped_tests = true
  #          junit.report
  #
  # @example Only show specific parts of your results
  #
  #          junit.parse "/path/to/output.xml"
  #          junit.headers = [:name, :file]
  #          junit.report
  #
  # @example Only show specific parts of your results
  #
  #          junit.parse "/path/to/output.xml"
  #          all_test = junit.tests.map(&:attributes)
  #          slowest_test = sort_by { |attributes| attributes[:time].to_f }.last
  #          message "#{slowest_test[:time]} took #{slowest_test[:time]} seconds"
  #
  #
  # @see  orta/danger-junit
  # @see  danger/danger
  # @see  artsy/eigen
  # @tags testing, reporting, junit, rspec, jasmine, jest, xcpretty
  #
  class DangerJunit < Plugin
    # All the tests for introspection
    #
    # @return   [Array<Ox::Element>]
    attr_accessor :tests

    # An array of XML elements that represent passed tests.
    #
    # @return   [Array<Ox::Element>]
    attr_accessor :passes

    # An array of XML elements that represent failed tests.
    #
    # @return   [Array<Ox::Element>]
    attr_accessor :failures

    # An array of XML elements that represent passed tests.
    #
    # @return   [Array<Ox::Element>]
    attr_accessor :errors

    # An array of XML elements that represent skipped tests.
    #
    # @return   [Array<Ox::Element>]
    attr_accessor :skipped

    # An attribute to make the plugin show a warning on skipped tests.
    #
    # @return   [Bool]
    attr_accessor :show_skipped_tests

    # An array of symbols that become the columns of your tests,
    # if `nil`, the default, it will be all of the attributes.
    #
    # @return   [Array<Symbol>]
    attr_accessor :headers

    # Parses an XML file, which fills all the attributes,
    # will `raise` for errors
    # @return   [void]
    def parse(file)
      require 'ox'
      raise "No JUnit file was found at #{file}" unless File.exist? file

      xml_string = File.read(file)
      @doc = Ox.parse(xml_string)

      suite_root = @doc.nodes.first.value == 'testsuites' ? @doc.nodes.first : @doc
      @tests = suite_root.nodes.map(&:nodes).flatten.select { |node| node.kind_of?(Ox::Element) && node.value == 'testcase' }

      failed_suites = suite_root.nodes.select { |suite| suite[:failures].to_i > 0 || suite[:errors].to_i > 0 }
      failed_tests = failed_suites.map(&:nodes).flatten.select { |node| node.kind_of?(Ox::Element) && node.value == 'testcase' }

      @failures = failed_tests.select do |test| 
        test.nodes.count > 0
      end.select do |test|
        node = test.nodes.first
        node.kind_of?(Ox::Element) && node.value == 'failure'
      end

      @errors = failed_tests.select do |test| 
        test.nodes.count > 0
      end.select do |test| 
        node = test.nodes.first
        node.kind_of?(Ox::Element) && node.value == 'error'
      end

      @skipped = tests.select do |test| 
        test.nodes.count > 0
      end.select do |test| 
        node = test.nodes.first
        node.kind_of?(Ox::Element) && node.value == 'skipped'
      end

      @passes = tests - @failures - @errors - @skipped
    end

    # Causes a build fail if there are test failures,
    # and outputs a markdown table of the results.
    #
    # @return   [void]
    def report
      return if failures.nil? # because danger calls `report` before loading a file
      warn("Skipped #{skipped.count} tests.") if show_skipped_tests && skipped.count > 0

      unless failures.empty? && errors.empty?
        fail('Tests have failed, see below for more information.', sticky: false)
        message = "### Tests: \n\n"

        tests = (failures + errors)

        # check the provided headers are available
        unless headers.nil?
          attributtesKey = tests.first.attributes.keys
          not_available_headers = headers.select { |header| not attributtesKey.include?(header) }
          raise "Some of headers provided aren't available in the JUnit report (#{not_available_headers})" unless not_available_headers.empty?
        end

        keys = headers || tests.first.attributes.keys
        attributes = keys.map(&:to_s).map(&:capitalize)

        # Create the headers
        message << attributes.join(' | ') + "|\n"
        message << attributes.map { |_| '---' }.join(' | ') + "|\n"

        # Map out the keys to the tests
        tests.each do |test|
          row_values = keys.map { |key| test.attributes[key] }.map { |v| auto_link(v) }
          message << row_values.join(' | ') + "|\n"
        end

        markdown message
      end
    end

    private

    def auto_link(value)
      if File.exist?(value) && defined?(@dangerfile.github)
        github.html_link(value, full_path: false)
      else
        value
      end
    end
  end
end
