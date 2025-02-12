classdef TemplateComponent < AComponent
    %This is a template component with the goal of illustrating a
    %component structure
    properties
        Object1Identifier
        Object2Identifier
        Object3Identifier
    end

    methods
        function obj = TemplateComponent()
            % This function call occurs when a new project is opened if
            % this component is included in the pipeline.
            % Define the default variable names here. If the object is an
            % input, the exact variable name needs to exist earlier in the
            % pipeline
            obj.Object1Identifier = 'CT';
            obj.Object2Identifier = 'MRI';
            obj.Object3Identifier = 'OutputVolume';
        end

        function Publish(obj)
            % Publish() is called only the first time that a component is
            % accessed
            % Define inputs and outputs here. Inputs and outputs need to
            % have data type definitions that can be found in
            % VERA/classes/engine/Data
            obj.AddInput(obj.Object1Identifier,'Volume');
            obj.AddInput(obj.Object2Identifier,'Volume');

            obj.AddOutput(obj.Object1Identifier,'Volume');
            obj.AddOutput(obj.Object3Identifier,'Volume');

            % External dependencies can be requested to be included. This
            % gets added to Settings.xml and the Settings menu.
            % obj.RequestDependency('ExampleDependency','folder');
        end

        function Initialize(obj)
            % Initialize() is called on configuration of the component
            % path = obj.GetDependency('ExampleDependency');
            % addpath(path);
        end

        function [obj1,obj3] = Process(obj,obj1,obj2)
            % Process() is called when the component is run. This is where
            % most of the functionality of a component should be included!
            obj3       = obj.CreateOutput(obj.Object3Identifier);
            obj3.Image = obj1.Image;
            obj3.Path  = obj1.Path;
        end
    end
end

