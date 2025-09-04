using GDWeave;
using util.LexicalTransformer;

namespace PondPortal;

public class Mod : IMod
{
	public Mod(IModInterface mi)
	{
		// Load your mod's configuration file
		var config = new Config(mi.ReadConfig<ConfigFileSchema>());

		mi.RegisterScriptMod(
			new TransformationRuleScriptModBuilder()
				.ForMod(mi)
				.Named("Pond Portal")
				.Patching("res://Scenes/Entities/Player/player.gdc")
				.AddRule(
					new TransformationRuleBuilder()
						.Named("Drowning override")
						.Do(Operation.Append)
						.Matching(
							TransformationPatternFactory.CreateFunctionDefinitionPattern("_on_water_detect_area_entered", ["area"])
						)
						.With(
							"""

							if area.is_in_group("water"):
								var PondPortal = get_node("/root/ToesPondPortal")
								var portaled = PondPortal.on_water_entered()
								if portaled: return

							""",
							1
						)
				)
				.Build()
		);
	}

	public void Dispose()
	{
		// Post-injection cleanup (optional)
	}
}
