# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_autolink'

module Supplejack
  module Controllers
    module Helpers
      extend ActiveSupport::Concern

      def search(special_params=nil)
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
      #
      def attribute(record, attributes, options={})
        options.reverse_merge!(:label => true, :label_inline => true, :limit => nil, :delimiter => ", ",
                                :link_path => false, :tag => Supplejack.attribute_tag, :label_tag => Supplejack.label_tag,
                                :label_class => Supplejack.label_class, :trans_key => nil, :link => false,
                                :extra_html => nil, :tag_class => nil)

        value = []
        attributes = [attributes] unless attributes.is_a?(Array)
        attributes.each do |attribute|
          if attribute.is_a?(String) && attribute.match(/\./)
            object, attr = attribute.split(".")
            v = record.try(object.to_sym).try(attr.to_sym) if object && attr
          else
            v = record.send(attribute)
          end

          if v.is_a?(Array)
            value += v.compact
          else
            value << v if v.present?
          end
        end

        value = value.first if value.size == 1
        attribute = attributes.first

        if value.is_a?(Array)
          if options[:limit] && options[:limit].to_i > 0
            value = value[0..(options[:limit].to_i-1)]
          end

          if options[:link_path]
            value = value.map {|v| link_to(v, send(options[:link_path], {:i => {attribute => v}})) }
          end

          if options[:link]
            value = value.map do |v|
              attribute_link_replacement(v, options[:link])
            end
          end

          value = value.join(options[:delimiter]).html_safe
          value = truncate(value, :length => options[:limit]) if options[:limit].to_i > 20
          value
        else
          if options[:limit] && options[:limit].to_i > 0
            value = truncate(value, :length => options[:limit].to_i)
          end

          if options[:link]
            value = attribute_link_replacement(value, options[:link])
          end
        end

        content = ""
        if options[:label]
          if options[:trans_key].present?
            translation = I18n.t(options[:trans_key], :default => attribute.to_s.capitalize) + ": "
          else
            i18n_class_name = record.class.to_s.tableize.downcase.gsub(/\//, "_")
            translation = "#{I18n.t("#{i18n_class_name}.#{attribute}", :default => attribute.to_s.capitalize)}: "
          end
          content = content_tag(options[:label_tag], translation, :class => options[:label_class]).html_safe
          content << "<br/>".html_safe unless options[:label_inline]
        end

        content << value.to_s
        content << options[:extra_html] if options[:extra_html]
        if value.present? and value != "Not specified"
          options[:tag] ? content_tag(options[:tag], content.html_safe, :class => options[:tag_class]) : content.html_safe
        end
      end

      # Displays the next and/or previous links based on the record and current search
      #
      # @params [ Dnz::Record ] The record object which has information about the next/previous record and pages.
      # @params [ Hash ] options Hash of options to customize the output,
      #   supported options: :prev_class, :next_class, :prev_label, :next_label
      #
      # @option options [ String ] :prev_class The CSS class to use on the previous button
      # @option options [ String ] :next_class The CSS class to use on the next button
      # @option options [ String ] :wrapper_class The CSS class to use on the wrapping span
      # @option options [ String ] :prev_label Any HTML to be put inside the previous button
      # @option options [ String ] :next_label Any HTML to be put inside the next button
      #
      def next_previous_links(record, html_options={})
        html_options.reverse_merge!({prev_class: "prev", next_class: "next", wrapper_class: 'nav', prev_label: nil, next_label: nil})

        return "" unless params[:search]
        links = "".html_safe

        options = search.options

        previous_label = html_options[:prev_label] ||= t('supplejack_client.previous', default: "Previous")
        next_label = html_options[:next_label] ||= t('supplejack_client.next', default: "Next")
        previous_label = previous_label.html_safe
        next_label = next_label.html_safe

        options[:path] = params[:search][:path].gsub(/(\W|\d)/, '') if params[:search] && params[:search][:path]

        if record.previous_record
          options[:page] = record.previous_page if record.previous_page.to_i > 1
          links += link_to(raw(previous_label), record_path(record.previous_record, search: options), class: html_options[:prev_class]).html_safe
        else
          links += content_tag(:span, previous_label, class: html_options[:prev_class])
        end

        if record.next_record
          options[:page] = record.next_page if record.next_page.to_i > 1
          links += link_to(raw(next_label), record_path(record.next_record, search: options), class: html_options[:next_class]).html_safe
        else
          links += content_tag(:span, next_label, class: html_options[:next_class])
        end

        content_tag(:span, links, class: html_options[:wrapper_class])
      end

      def attribute_link_replacement(value, link_pattern)
        if link_pattern.is_a?(String)
          link_pattern = URI.decode(link_pattern)
          url = link_pattern.gsub("{{value}}", value)
          link_to(value, url)
        else
          auto_link value
        end
      end

    end
  end
end
