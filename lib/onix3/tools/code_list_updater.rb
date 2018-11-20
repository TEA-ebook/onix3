require 'nokogiri'
require 'yaml'


module Onix3
  module Tools
    class CodeListUpdater
      
      ENCODING = "UTF-8"

      include Onix3::Tools::Path

      def update_with(code_list_file)
        doc = Nokogiri::Slop File.read(code_list_file, nil, nil, encoding: ENCODING)
        doc.ONIXCodeTable.CodeList.each do |list|
          update_code_list(list)
        end
      end

      def update_code_list(list)
        list_number = list.CodeListNumber.content
        l = list_content(list_number)
        l[:description] = list.CodeListDescription.content
        l[:issue_number] = list.IssueNumber.content
        l[:number] = list_number
        l[:codes] ||= { }
        
        code_nodes = list.at_xpath("Code")
        unless code_nodes.nil?
          list.Code.each do |code|
            update_code_in_list(code, l)
          end
        end
        File.truncate(list_filename(list_number), 0)
        File.write(list_filename(list_number), YAML.dump(l), 0, encoding: ENCODING)
      end

      def update_code_in_list(xml, list)
        value = xml.CodeValue.content
        list[:codes][value] = {
          value: value,
          description: xml.CodeDescription.content,
          notes: xml.CodeNotes.content,
          issue_number: xml.IssueNumber.content
        }
      end

      def list_filename(number)
        File.join(code_lists_path, "list_#{number.to_s.rjust(3,'0')}.yml")
      end

      def list_content(number)
        list_filename = self.list_filename(number)
        File.exists?(list_filename) ? YAML.load( File.read(list_filename, nil, nil, encoding: ENCODING) ) : { number: number }
      end

    end

  end
end
