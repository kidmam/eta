module ETA.BasicTypes.Module where
import ETA.Utils.FastString

data Module
data ModuleName
data UnitId
data InstalledUnitId
newtype ComponentId = ComponentId FastString

moduleName :: Module -> ModuleName
moduleUnitId :: Module -> UnitId
unitIdString :: UnitId -> String
