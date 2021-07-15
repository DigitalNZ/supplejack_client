# frozen_string_literal: false

require 'rails_autolink'
# FIXME: make this module presentable
module Supplejack
  module Controllers
    module Helpers
      extend ActiveSupport::Concern

      def search(special_params = nil)
        return @supplejack_search if @supplejack_search

        klass = Supplejack.search_klass ? Supplejack.search_klass.classify.constantize : Supplejack::Search
        @supplejack_search = klass.new(special_params || params[:search] || params)
      end

      # Displays a record attribute with a label and allows you to customize the
      # HTML markup generated. It will not display anything if the value is blank or nil.
      #
      # @param [ Record ] record Class which includes the Supplejack::Record module
      # @param [ Symbol ] attribute The name of the attribute to return
      # @param [ Hash ] options Hash of options to customize the output,
      #   supported options: :label, :limit, :delimiter, :link_path, :tag
      #
      # @option options [ true, false ] :label Display the attribute name
      # @option options [ String ] :label_tag HTML tag to surround label
      # @option options [ String ] :label_class CSS class to apply to label_tag
      # @option options [ Integer ] :limit Number of charachters to truncate or number of values (when multivalue field)
      # @option options [ Integer ] :delimiter Used to separate multi value attributes
      # @option options [ String ] :link_path The method name of a routes path when provided it will generate links for every value
      # @option options [ Symbol ] :tag HTML tag to wrap the label and value
      # @option options [ true, false, String ] :link When true will try to make the value into a link, When is a string it will try
      #                                               to find a {{value}} within the string and replace it with the value.
      # @option options [ String ] :extra_html HTML which will be included inside the tag at the end.
      # @option options [ Symbol ] :tag_class The class for the attribute tag
      #
      # @return [ String ] A HTML snippet with the attribute name and value
      # rubocop: disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def attribute(record, attributes, options = {})
        options.reverse_merge!(label: true, label_inline: true, limit: nil, delimiter: ', ',
                               link_path: false, tag: Supplejack.attribute_tag, label_tag: Supplejack.label_tag,
                               label_class: Supplejack.label_class, trans_key: nil, link: false,
                               extra_html: nil, tag_class: nil)

        value = []
        attributes = [attributes] unless attributes.is_a?(Array)
        attributes.each do |attribute|
          if attribute.is_a?(String) && attribute.match(/\./)
            object, attr = attribute.split('.')
            v = record.try(object.to_sym).try(attr.to_sym) if object && attr
          else
            v = record.send(attribute)
          end

          if v.is_a?(Array)
            value += v.compact
          elsif v.present?
            value << v
          end
        end

        value = value.first if value.size == 1
        attribute = attributes.first

        if value.is_a?(Array)
          if options[:limit] && options[:limit].to_i > 0
            value = value[0..(options[:limit].to_i - 1)]
          end

          if options[:link_path]
            value = value.map { |v| link_to(v, send(options[:link_path], i: { attribute => v })) }
          end

          if options[:link]
            value = value.map do |v|
              attribute_link_replacement(v, options[:link])
            end
          end

          value = value.join(options[:delimiter]).html_safe
          value = truncate(value, length: options[:limit]) if options[:limit].to_i > 20
          value
        else
          if options[:limit] && options[:limit].to_i > 0
            value = truncate(value, length: options[:limit].to_i)
          end

          if options[:link]
            value = attribute_link_replacement(value, options[:link])
          end
        end

        content = ''
        if options[:label]
          if options[:trans_key].present?
            translation = "#{I18n.t(options[:trans_key], default: attribute.to_s.capitalize)}: "
          else
            i18n_class_name = record.class.to_s.tableize.downcase.gsub(%r{/}, '_')
            translation = "#{I18n.t("#{i18n_class_name}.#{attribute}", default: attribute.to_s.capitalize)}: "
          end
          content = content_tag(options[:label_tag], translation, class: options[:label_class]).html_safe
          content << '<br/>'.html_safe unless options[:label_inline]
        end

        content << value.to_s
        content << options[:extra_html] if options[:extra_html]
        if value.present? && (value != 'Not specified')
          options[:tag] ? content_tag(options[:tag], content.html_safe, class: options[:tag_class]) : content.html_safe
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # Displays the next and/or previous links based on the record and current search
      #
      # @params [ Supplejack::Record ] The record object which has information about the next/previous record and pages.
      # @params [ Hash ] options Hash of options to customize the output,
      #   supported options: :prev_class, :next_class, :prev_label, :next_label
      #
      # @option options [ String ] :prev_class The CSS class to use on the previous button
      # @option options [ String ] :next_class The CSS class to use on the next button
      # @option options [ String ] :wrapper_class The CSS class to use on the wrapping span
      # @option options [ String ] :prev_label Any HTML to be put inside the previous button
      # @option options [ String ] :next_label Any HTML to be put inside the next button
      # @option options [ String ] :include_querystring Includes the query string in the button links
      #
      def next_previous_links(record, html_options = {})
        html_options.reverse_merge!(prev_class: 'prev', next_class: 'next', wrapper_class: 'nav', prev_label: nil, next_label: nil)

        return '' unless params[:search]

        links = ''.html_safe
        options = search.options
        options[:path] = params[:search][:path].gsub(/(\W|\d)/, '') if params[:search] && params[:search][:path]

        links = previous_record_link(links, record, options, html_options)
        links = next_record_link(links, record, options, html_options)

        content_tag(:span, links, class: html_options[:wrapper_class])
      end

      def previous_record_link(links, record, options, html_options)
        previous_label = html_options[:prev_label] ||= t('supplejack_client.previous', default: 'Previous')
        previous_label = previous_label.html_safe

        if record.previous_record
          options[:page] = record.previous_page if record.previous_page.to_i > 1
          path = record_path(record.previous_record, search: options)
          path = path.split('?')[0] if path.include?('?') && html_options[:include_querystring]
          path = "#{path}?#{request.query_string}" if html_options[:include_querystring]
          links += link_to(raw(previous_label), path, class: html_options[:prev_class]).html_safe
        else
          links += content_tag(:span, previous_label, class: html_options[:prev_class])
        end
        links
      end

      def next_record_link(links, record, options, html_options)
        next_label = html_options[:next_label] ||= t('supplejack_client.next', default: 'Next')
        next_label = next_label.html_safe

        if record.next_record
          options[:page] = record.next_page if record.next_page.to_i > 1
          path = record_path(record.next_record, search: options)
          path = path.split('?')[0] if path.include?('?') && html_options[:include_querystring]
          path = "#{path}?#{request.query_string}" if html_options[:include_querystring]
          links += link_to(raw(next_label), path, class: html_options[:next_class]).html_safe
        else
          links += content_tag(:span, next_label, class: html_options[:next_class])
        end
        links
      end

      def attribute_link_replacement(value, link_pattern)
        if link_pattern.is_a?(String)
          link_pattern = URI.decode(link_pattern)
          url = link_pattern.gsub('{{value}}', value)
          link_to(value, url)
        else
          auto_link value
        end
      end

      # Generates hidden fields with all the filters of a search object
      # It is used in forms, so that when a user enteres another term in the search
      # box the state of the search is preserved
      #
      # @param [ Supplejack::Search ] search A instance of the Supplejack::Search class
      # @param [ Hash ] options Hash of options to remove any filter
      #
      # @option options [ Array ] except A array of fields which should not generate a hidden field
      #
      # @return [ String ] A HTML snippet with hidden fields
      #
      def form_fields(search, options = {})
        if search
          tags = ''.html_safe

          fields = %i[record_type sort direction]
          fields.delete(:record_type) if search.record?

          if options[:except].try(:any?)
            fields.delete_if { |field| options[:except].include?(field) }
          end

          fields.each do |field|
            tags += hidden_field_tag(field.to_s, search.send(field)) if search.send(field).present?
          end

          { i: :i_unlocked, il: :i_locked, h: :h_unlocked, hl: :h_locked }.each_pair do |symbol, instance_name|
            next unless Supplejack.sticky_facets || %i[il hl].include?(symbol) || options[:all_filters]

            filters = begin
              search.url_format.send(instance_name)
            rescue StandardError
              {}
            end

            filters.each do |name, value|
              field_name = value.is_a?(Array) ? "#{symbol}[#{name}][]" : "#{symbol}[#{name}]"
              values = *value
              values.each { |v| tags << hidden_field_tag(field_name, v) }
            end
          end

          tags
        end
      end

      # Returns a link with all existing search options except the specified in the params
      #
      # @param [ Symbol ] name The name of the facet. Ex: :category, :subject
      # @param [ String ] value The value withing the facet. Ex: "Wellington", "Books", etc..
      # @param [ String ] path_name The name of the path used to generate the url path.
      #   For example if you have a records_path route in your app, then specify "records"
      #   and it will call the records_path method
      # @param [ Hash ] options Set of options to customize the output
      # @param [ Hash ] html_options HTML options that are passed directly to the link_to method
      #
      # @return [ String ] A link to with the correct search options.
      #
      def link_to_remove_filter(name, value, path_name, options = {}, html_options = {}, &block)
        path = generate_path(path_name, search.options(except: [{ name => value }, :page]))
        link_text = options[:display_name].presence || I18n.t("facets.values.#{value}", default: value)
        link_to block_given? ? capture(&block) : link_text, path.html_safe, html_options
      end

      # Returns a link with the existing search options and adds the specified facet and value
      #
      # @param [ Symbol ] name The name of the facet. Ex: :category, :subject
      # @param [ String ] value The value withing the facet. Ex: "Wellington", "Books", etc..
      # @param [ String ] path_name The name of the path used to generate the url path.
      #   For example if you have a records_path route in your app, then specify "records"
      #   and it will call the records_path method
      # @param [ Hash ] options Set of options to customize the output
      # @param [ Hash ] html_options HTML options that are passed directly to the link_to method
      #
      # @return [ String ] A link to with the correct search options.
      #
      def link_to_add_filter(name, value, path_name, options = {}, html_options = {}, &block)
        symbol = search.record_type == 0 ? :i : :h
        options[:except] = Util.array(options[:except]) + [:page]
        path = generate_path(path_name, search.options(plus: { symbol => { name => value } }, except: options[:except]))
        link_text = options[:display_name].presence || I18n.t("facets.values.#{value}", default: value)
        link_to block_given? ? capture(&block) : link_text, path.html_safe, html_options
      end

      def link_to_lock_filter(name, value, path_name, options = {}, html_options = {}, &block)
        symbol = search.record_type == 0 ? :il : :hl
        path = generate_path(path_name, search.options(except: [{ name => value }], plus: { symbol => { name => value } }))
        link_text = options[:display_name].presence || I18n.t("facets.values.#{value}", default: value)
        link_to block_given? ? capture(&block) : link_text, path.html_safe, html_options
      end

      # Provides a link to record landing page that is augmented with a persisted search object
      # Used in results listings
      #
      # @params [ String ] name A text to display in the link (not required if block is passed)
      # @params [ String ] url The url for the link
      # @params [ Hash ] search_options The options to pass in the search options (usually @search.options)
      # @params [ Hash ] html_options The options to pass to link_to
      # @params [ Block ] &block A block containing ERB, this replaces the name parameter
      #
      def link_to_record(*args, &block)
        if block_given?
          name = capture(&block)
          url = args[0]
          search_options = args[1] || {}
          html_options = args[2] || {}
        else
          name = args[0]
          url = args[1]
          search_options = args[2] || {}
          html_options = args[3] || {}
        end

        url = "#{url} + ? #{{ search: search_options }.to_query}" if search_options.try(:any?)
        link_to(name, url, html_options)
      end

      def generate_path(name, options = {})
        segments = name.split('.')

        case segments.size
        when 1 then send("#{segments[0]}_path", options)
        when 2 then send(segments[0]).send("#{segments[1]}_path", options)
        end
      end
    end
  end
end
