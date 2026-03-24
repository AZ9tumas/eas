local TextEffects = require(script.Parent.Parent);

return function(uiInstance: GuiObject, speed: number, size: number)
    local mainStroke = TextEffects.Stroke.new(uiInstance, size);
    local strokeGradient = TextEffects.Gradient.new(mainStroke.Instance, TextEffects.Templates.Rainbow.Color, 0);
    --strokeGradient:SetOffsetSpeed(-speed, 1);
    strokeGradient:SetOffsetSpeed(-speed, 3);
    return {
        Effects = { strokeGradient, mainStroke }
    };
end