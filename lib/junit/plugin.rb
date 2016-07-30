module Danger
  # Report, or inspect any JUnit XML formatted test suite report.
  #
  # Testing frameworks have standardized on the JUnit XML format for
  # reporting results, this means that projects using Rspec, Jasmine, Mocha,
  # XCTest and more - can all use the same Danger error reporting. Perfect.
  #
  # You can see some examples on [this page from Circle CI](https://circleci.com/docs/test-metadata/)
  # about how you can add JUnit XML output for your testing projects.
  #
  # @example Parse the XML file, and let the plugin do your reporting
  #
  #          junit.parse "/path/to/output.xml"
  #          junit.report
  #
  # @example Let the plugin parse the XML file, and report yourself
  #
  #          junit.parse "/path/to/output.xml"
  #          fail("Tests failed") unless junit.fails.empty?
  #
  # @example Warn on a report about skipped tests
  #
  #          junit.parse "/path/to/output.xml"
  #          junit.show_skipped_tests = true
  #          junit.report
  #
  # @see  orta/danger-junit, danger/danger, artsy/eigen
  # @tags testing, reporting, junit, rspec, jasmine, jest, xcpretty
  #
  class DangerJunit < Plugin
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

    # Parses an XML file, which fills all the attributes
    # will `raise` for errors
    # @return   [void]
    def parse(file)
      require 'ox'
      raise "No Junit file was found at #{file}" unless File.exist? file

      xml_string = File.read file
      @doc = Ox.parse xml_string

      suite_root = @doc.nodes.first.value == 'testsuites' ? @doc.nodes.first : @doc
      tests = suite_root.nodes.map(&:nodes).flatten.select { |node| node.value == 'testcase' }

      failed_suites = suite_root.nodes.select { |suite| suite[:failures].to_i > 0 || suite[:errors].to_i > 0 }
      failed_tests = failed_suites.map(&:nodes).flatten.select { |node| node.value == 'testcase' }

      @failures = failed_tests.select { |test| test.nodes.count > 0 }.select { |test| test.nodes.first.value == 'failure' }

      @errors = failed_tests.select { |test| test.nodes.count > 0 }.select { |test| test.nodes.first.value == 'error' }

      @skipped = tests.select { |test| test.nodes.count > 0 }.select { |test| test.nodes.first.value == 'skipped' }

      @passes = tests - @failures - @errors - @skipped
    end

    # Causes a build fail if there are test failures,
    # and outputs a markdown table of the results.
    #
    # @return   [void]
    def report
      warn("Skipped #{skipped.count} tests.") if show_skipped_tests && skipped.count > 0

      unless failures.empty? && errors.empty?
        fail("Tests have failed, see below for more information.", sticky: false)
        message = "### Tests: \n\n"

        tests = (failures + errors)
        keys = tests.first.attributes.keys
        attributes = keys.map(&:to_s).map(&:capitalize)

        # Create the header
        message << attributes.join(' | ') + "|\n"
        message << attributes.map { |_| '---' }.join(' | ') + "|\n"

        tests.each do |test|
          message << test.attributes.values.join(' | ') + "|\n"
        end

        markdown message
      end
    end
  end
end
